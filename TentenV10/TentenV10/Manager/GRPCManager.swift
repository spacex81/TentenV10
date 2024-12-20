import Foundation
import UIKit
import GRPC
import NIO

final class GRPCManager: ObservableObject {
    static let shared = GRPCManager()
    
    private lazy var repoManager: RepositoryManager = {
        return RepositoryManager.shared
    }()
    
    // MARK: - Properties
    private var eventLoopGroup: EventLoopGroup?
    private var channel: GRPCChannel?
    private var pingPongCall: BidirectionalStreamingCall<Service_ClientMessage, Service_Ping>?
    private var friendListenerCall: BidirectionalStreamingCall<Service_FriendListenerRequest, Service_FriendListenerResponse>?

    @Published var serverResponse: String = "Waiting for server response..."
    @Published var isConnected: Bool = false
    @Published var friendStatuses: [String: String] = [:]
    {
        didSet {
            printFriendStatuses()
        }
    }
    
    func printFriendStatuses() {
        NSLog("LOG: ====== Friend Statuses Updated ======")
        for (friendID, status) in friendStatuses {
            if status == "foreground" {
                NSLog("LOG: Friend ID: \(friendID) | Status: \(status)")
            }
        }
        NSLog("LOG: =====================================")
    }
    
    private let lock = NSLock() // Lock to prevent multiple connections
    private var isConnecting = false // Track if a connection is currently being established
    
    //
    var appState: String = "foreground" {
        didSet {
            NSLog("LOG: appState: \(appState)")
        }
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func handleAppDidEnterBackground() {
        self.appState = "background"
        if isConnected {
            disconnect()
        }
    }

    @objc private func handleAppWillEnterForeground() {
        self.appState = "foreground"
        if !isConnected, let userRecord = repoManager.userRecord {
            connect(clientID: userRecord.id, friends: userRecord.friends)
        }
    }
    //
    
    // MARK: - Connect to gRPC Server
    func connect(clientID: String, friends: [String]) {
        NSLog("LOG: GRPCManager-connect: clientID=\(clientID), friends=\(friends)")
        
        lock.lock()
        defer { lock.unlock() }
        
        if isConnected {
            NSLog("LOG: GRPCManager-connect: Already connected")
            return
        }
        
        if isConnecting {
            NSLog("LOG: GRPCManager-connect: Connection in progress, skipping new connect request")
            return
        }
        
        NSLog("LOG: GRPCManager-connect: Starting connection process")
        isConnecting = true
        
        DispatchQueue.global().async {
            do {
                // 1. Create an EventLoopGroup for handling async work
                let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
                self.eventLoopGroup = group
                
                // 2. Create a channel to the gRPC server
                let channel = try GRPCChannelPool.with(
                    target: .host("komaki.tech", port: 443),
                    transportSecurity: .tls(.makeClientConfigurationBackedByNIOSSL()),
                    eventLoopGroup: group
                )
                self.channel = channel
                
                // 3. Create the gRPC client
                let client = Service_ServerNIOClient(channel: channel)
                
                DispatchQueue.main.async {
                    self.serverResponse = "LOG: ✅ Connected to gRPC Server!"
                    self.isConnected = true
                    self.isConnecting = false
                }
                
                // 🔥 Start Ping-Pong Communication
                self.startPingPong(client: client, clientID: clientID)
                
                // 🔥 Start Friend Listener
                self.startFriendListener(client: client, friends: friends)
                
            } catch {
                DispatchQueue.main.async {
                    self.serverResponse = "LOG:❌ Failed to connect: \(error.localizedDescription)"
                    self.isConnected = false
                    self.isConnecting = false
                }
            }
        }
    }
    
    // MARK: - Start the Ping-Pong Communication
    private func startPingPong(client: Service_ServerNIOClient, clientID: String) {
        let call = client.communicate { response in
            DispatchQueue.main.async {
                self.serverResponse = "LOG: 📨 Ping from Server: \(response.message)"
            }
            
            if let call = self.pingPongCall {
                if self.appState == "foreground" {
                    self.sendPong(call: call)
                }
            }
        }
        
        self.pingPongCall = call
        
        var clientHello = Service_ClientHello()
        clientHello.clientID = clientID
        
        var clientMessage = Service_ClientMessage()
        clientMessage.clientHello = clientHello
        
        call.sendMessage(clientMessage).whenComplete { result in
            switch result {
            case .success:
//                print("LOG: ✅ Sent ClientHello message successfully")
                break
            case .failure(let error):
                print("LOG: ❌ Failed to send ClientHello message: \(error.localizedDescription)")
            }
        }
        
        // ✅ Notify when the pingpong listener is disconnected
        call.status.whenComplete { result in
            switch result {
            case .success:
                NSLog("LOG: PingPong listener connection ended gracefully")
            case .failure(let error):
                NSLog("LOG: PingPong listener disconnected with error: \(error.localizedDescription)")
            }
            
            // You can trigger reconnection logic here if needed
        }
    }
    
    // MARK: - Start the Friend Listener
    func startFriendListener(client: Service_ServerNIOClient, friends: [String]) {
        let call = client.friendListener { response in
            DispatchQueue.main.async {
                switch response.message {
                
                case .friendUpdate(let friendUpdate):
                    // Handle friend update
//                    self.friendStatuses[friendUpdate.clientID] = friendUpdate.isOnline
                    let statusString = self.convertStatusToString(status: friendUpdate.status)
                    self.friendStatuses[friendUpdate.clientID] = statusString
                    
                case .keepalivePing(let keepalivePing):
                    // Handle keepalive ping
//                    NSLog("LOG: Received KeepAlivePing from server: \(keepalivePing.message)")
                    
                    // Send KeepAliveAck to the server
                    var keepAliveAck = Service_KeepAliveAck()
                    keepAliveAck.message = "ACK from iOS client"
                    
                    var request = Service_FriendListenerRequest()
                    request.message = .keepaliveAck(keepAliveAck)
                    
                    if let call = self.friendListenerCall {
                        call.sendMessage(request).whenComplete { result in
                            switch result {
                            case .success:
//                                NSLog("LOG: Sent KeepAliveAck successfully")
                                break
                            case .failure(let error):
                                NSLog("LOG: Failed to send KeepAliveAck: \(error.localizedDescription)")
                            }
                        }
                    }
                case .none:
                    NSLog("LOG: ⚠️ Received an unknown response from server")
                }
            }
        }
        
        self.friendListenerCall = call
        
        // Send the FriendList to the server
        var friendList = Service_FriendList()
        friendList.friendIds = friends
        
        var request = Service_FriendListenerRequest()
        request.message = .friendList(friendList)
        
        call.sendMessage(request).whenComplete { result in
            switch result {
            case .success:
                NSLog("LOG: 📡 Sent FriendList message successfully")
            case .failure(let error):
                NSLog("LOG: ❌ Failed to send FriendList message: \(error.localizedDescription)")
            }
        }
        
        // ✅ Notify when the friend listener is disconnected
        call.status.whenComplete { result in
            switch result {
            case .success:
                NSLog("LOG: ℹ️ Friend listener connection ended gracefully")
            case .failure(let error):
                NSLog("LOG: ❌ Friend listener disconnected with error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Disconnect from gRPC Server
    func disconnect() {
        DispatchQueue.global().async {
            self.lock.lock()
            defer { self.lock.unlock() }
            
            if !self.isConnected {
                NSLog("LOG: GRPCManager-disconnect: Already disconnected")
                return
            }
            
            self.pingPongCall?.cancel(promise: nil)
            self.pingPongCall = nil
            
            self.friendListenerCall?.cancel(promise: nil)
            self.friendListenerCall = nil
            
            self.channel?.close().whenComplete { _ in }
            self.channel = nil
            
            try? self.eventLoopGroup?.syncShutdownGracefully()
            self.eventLoopGroup = nil
            
            DispatchQueue.main.async {
                self.isConnected = false
                self.serverResponse = "LOG: 🔴 Disconnected from gRPC Server"
                self.friendStatuses = [:]
            }
        }
    }
    
    // MARK: - Send Pong Message
    private func sendPong(call: BidirectionalStreamingCall<Service_ClientMessage, Service_Ping>) {
        var pong = Service_Pong()
        pong.status = self.appState == "foreground" ? .foreground : .background
        
        var clientMessage = Service_ClientMessage()
        clientMessage.pong = pong
        
        call.sendMessage(clientMessage).whenComplete { result in
            if case .failure(let error) = result {
                NSLog("LOG: ❌ Failed to send Pong message: \(error.localizedDescription)")
            }
        }
        NSLog("LOG: GRPCManager-sendPong: Sent Pong message")
    }
}

extension GRPCManager {
    private func convertStatusToString(status: Service_FriendUpdate.Status) -> String {
        switch status {
        case .offline:
            return "offline"
        case .foreground:
            return "foreground"
        case .background:
            return "background"
        case .UNRECOGNIZED(let value):
            return "unrecognized(\(value))"
        default:
            return "unknown"
        }
    }
}
