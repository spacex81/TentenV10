import Foundation
import UserNotifications
import LiveKit

class LiveKitManager: ObservableObject, RoomDelegate {
    static let shared = LiveKitManager()
    
    weak var repoManager: RepositoryManager?
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false
    @Published var isLocked: Bool = false 
    @Published var isPressing: Bool = false {
        didSet {
            NSLog("LOG: LiveKitManager-isPressing : \(isPressing ? "true" : "false")")
        }
    }

    var room: Room?

    let livekitUrl = "wss://tentwenty-bp8gb2jg.livekit.cloud"
    let handleLiveKitTokenUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/handleLivekitToken"
    let handleRegularNotificationUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/handleRegularNotification"

    init() {
        let roomOptions = RoomOptions(adaptiveStream: true, dynacast: true)
        room = Room(delegate: self, roomOptions: roomOptions)
    }
}

extension LiveKitManager {
    func connect(roomName: String) async {
        if roomName == "testRoom" {
            NSLog("LOG: Connecting to LiveKit with default room name")
        } else {
            NSLog("LOG: Connecting to LiveKit with room name: \(roomName)")
        }
        guard let room  = self.room else {
            print("Room is not set")
            return
        }
        
        let token = await fetchLivekitToken(roomName: roomName)
        guard let livekitToken = token else {
            print("Failed to fetch livekit access token")
            return
        }
        
        do {
            try await room.connect(url: livekitUrl, token: livekitToken)
            DispatchQueue.main.async {
                self.isConnected = true
            }
            NSLog("LOG: LiveKit Connected")
        } catch {
            print("Failed to connect to LiveKit Room")
        }
    }
    
    func disconnect() async {
        NSLog("LOG: Disconnecting from LiveKit")
        guard let room  = self.room else {
            print("Room is not set")
            return
        }

        if isPublished {
            await unpublishAudio()
        }
        await room.disconnect()
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.repoManager?.currentState = .idle
        }
        
        NSLog("LOG: LiveKit disconnected")
    }
    
    func publishAudio() async {
        NSLog("LOG: Start enabling microphone for LiveKit audio track")
        guard let room = self.room else {
            NSLog("Room is not set")
            return
        }

        do {
            try await room.localParticipant.setMicrophone(enabled: true)
            NSLog("LOG: Microphone enabled and LiveKit Audio track Published")
        } catch {
            NSLog("Failed to enable microphone for LiveKit Room: \(error)")
        }
    }
    
    func unpublishAudio() async {
        guard let room = self.room else {
            NSLog("Room is not set")
            return
        }

        do {
            // Disable the microphone
            try await room.localParticipant.setMicrophone(enabled: false)
            DispatchQueue.main.async {
                self.isPublished = false
            }
            NSLog("LOG: Microphone disabled and LiveKit Audio track unpublished")
        } catch {
            NSLog("Failed to disable microphone and unpublish audio track: \(error)")
        }
    }

    func fetchLivekitToken(roomName: String) async -> String? {
        guard let url = URL(string: handleLiveKitTokenUrl) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = ["roomName": roomName]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.httpBody = jsonData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return json?["livekitToken"] as? String
        } catch {
            NSLog("Failed to fetch token: \(error)")
            return nil
        }
    }
}

// MARK: LiveKit Delegate
extension LiveKitManager {
    func room(_ room: Room, participant: RemoteParticipant?, didReceiveData data: Data, forTopic topic: String) {
        // Convert the received data to a string (or other appropriate format)
        guard let message = String(data: data, encoding: .utf8) else {
            print("Failed to decode received data")
            return
        }

        // Check if the received message is 'readyToTalk'
        if message == "readyToTalk" {
            print("Received 'readyToTalk' message. Setting isPublished to true.")
            DispatchQueue.main.async {
                self.isPublished = true
                self.repoManager?.currentState = .isSpeaking
            }
        } else {
            print("Received data: \(message). Ignored.")
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        sendMessageToRemoteParticipant(message: "readyToTalk")
        self.repoManager?.currentState = .isListening
        sendLocalNotification(title: "Remote Participant", body: "Remote participant is talking")
        NSLog("LOG: Ready to listen to remote audio stream")
    }
    
    // remote participant left the room
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        NSLog("LOG: remote participant left the room")
        // when this callback runs when isPressing is true
        // this should not run
        if !isPressing {
            Task {
                isLocked = false
                NSLog("LOG: isLocked is \(isLocked ? "locked" : "unlocked")")
                await unpublishAudio()
                await disconnect()
            }
        }
    }
    
    
    func sendMessageToRemoteParticipant(message: String) {
        guard let room = room else {
            print("Room is not set")
            return
        }
        
        let data = Data(message.utf8)
        Task {
            do {
                try await room.localParticipant.publish(data: data)
            } catch {
                print("Failed to send data: \(error)")
            }
        }
    }
    
    func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add notification request: \(error)")
            }
        }
    }
}
