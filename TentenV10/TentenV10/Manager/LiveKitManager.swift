import Foundation
import UserNotifications
import LiveKit

class LiveKitManager: ObservableObject, RoomDelegate {
    static let shared = LiveKitManager()
    
    weak var repoManager: RepositoryManager?
    weak var grpcManager: GRPCManager?
    var notificationManager: NotificationManager?
    weak var collectionViewController: CustomCollectionViewController?
    
    @Published var isConnected: Bool = false {
        didSet {
//            NSLog("LOG: LiveKitManager-isConnected: \(isConnected)")
        }
    }
    @Published var isConnected2: Bool = false {
        didSet {
//            NSLog("LOG: LiveKitManager-isConnected: \(isConnected)")
        }
    }
    @Published var isPublished: Bool = false {
        didSet {
            NSLog("LOG: LiveKitManager-isPublished: \(isPublished)")
        }
    }
    @Published var isLocked: Bool = false  {
        didSet {
//            NSLog("LOG: LiveKitManager-isLocked : \(isLocked ? "true" : "false")")
            if !isLocked {
                repoManager?.collectionViewController?.reloadData()
            }
        }
    }
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
        NSLog("LOG: LiveKitManager-connect: start")
//        NSLog("LOG: roomName: \(roomName)")
        
        guard let room = self.room else {
            print("Room is not set")
            return
        }
        
//        NSLog("LOG: Fetching LiveKit token")
        
        // Check if the task has been canceled before fetching the token
        do {
            try Task.checkCancellation()
        } catch {
            NSLog("LOG: Fetching token canceled due to task cancellation.")
            return
        }
        
        let token = await fetchLivekitToken(roomName: roomName)
        
        // Check if the task has been canceled after attempting to fetch the token
        do {
            try Task.checkCancellation()
        } catch {
            NSLog("LOG: Token fetch process canceled due to task cancellation.")
            return
        }
        
        guard let livekitToken = token else {
            if Task.isCancelled {
                NSLog("LOG: Token fetching failed due to task cancellation.")
            } else {
                print("Failed to fetch LiveKit access token.")
            }
            return
        }
        
        do {
            // Check again before attempting to connect
            try Task.checkCancellation()
            
//            NSLog("LOG: Connecting to LiveKit room")
            try await room.connect(url: livekitUrl, token: livekitToken)
            DispatchQueue.main.async {
                self.isConnected = true
                self.isConnected2 = true
            }
            NSLog("LOG: LiveKit Connected")
        } catch {
            if Task.isCancelled {
                NSLog("LOG: Connection canceled due to task cancellation.")
            } else {
                print("Failed to connect to LiveKit Room: \(error)")
            }
        }
    }
    
    func disconnect() async {
//        NSLog("LOG: LiveKitManager-disconnect")
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
        
//        NSLog("LOG: LiveKit disconnected")
    }
    
    func publishAudio() async {
        NSLog("LOG: LiveKitManager-publishAudio: start")
        
        // Check if the task has been canceled before starting
        do {
            try Task.checkCancellation()
        } catch {
            NSLog("LOG: Publishing audio canceled due to task cancellation.")
            return
        }
        
        guard let room = self.room else {
            NSLog("Room is not set")
            return
        }
        
        do {
            // Check if the task has been canceled before enabling the microphone
            try Task.checkCancellation()
            
//            NSLog("LOG: LiveKitManager-publishAudio-setMicrophone: start")
            try await room.localParticipant.setMicrophone(enabled: true)
//            NSLog("LOG: LiveKitManager-publishAudio-setMicrophone: finish")
        } catch {
            if Task.isCancelled {
                NSLog("LOG: Microphone enabling canceled due to task cancellation.")
            } else {
                NSLog("Failed to enable microphone for LiveKit Room: \(error)")
            }
        }
        NSLog("LOG: LiveKitManager-publishAudio: finish")
    }
    
    func unpublishAudio() async {
        NSLog("LOG: LiveKitManager-unpublishAudio")
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
//            NSLog("LOG: Microphone disabled and LiveKit Audio track unpublished")
        } catch {
            NSLog("Failed to disable microphone and unpublish audio track: \(error)")
        }
    }
    
    func fetchLivekitToken(roomName: String) async -> String? {
        guard let url = URL(string: handleLiveKitTokenUrl) else {
            NSLog("Failed to create URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonBody: [String: Any] = ["roomName": roomName]
        
        do {
            // Check for task cancellation before setting up the request body
            try Task.checkCancellation()
            
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.httpBody = jsonData
            
            // Check for task cancellation before sending the request
            try Task.checkCancellation()
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Check for task cancellation before processing the response
            try Task.checkCancellation()
            
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            return json?["livekitToken"] as? String
        } catch {
            if Task.isCancelled {
                NSLog("LOG: Token fetch canceled due to task cancellation.")
            } else {
                NSLog("Failed to fetch token: \(error)")
            }
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
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
//        NSLog("LOG: LiveKitManager-participantDidConnect-RemoteParticipant")
        if let repoManager = self.repoManager, notificationManager == nil {
            notificationManager = NotificationManager.shared(repoManager: repoManager, authManager: AuthManager.shared)
        }

        if let receiverToken = repoManager?.selectedFriend?.deviceToken {
            if isPublished {
                notificationManager?.sendRemoteNotification(type: "connect", receiverToken: receiverToken)
            } else {
                // MARK: if isPublished is false than wait a little bit before sending notification
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.notificationManager?.sendRemoteNotification(type: "connect", receiverToken: receiverToken)
                }
            }
        }
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        sendMessageToRemoteParticipant(message: "readyToTalk")
        self.repoManager?.currentState = .isListening
        // Send notification when the friend starts speaking
//        self.repoManager?.sendLocalNotification(type: "startSpeaking")
        NSLog("LOG: Ready to listen to remote audio stream")
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        // Send notification when the friend stops speaking
//        self.repoManager?.sendLocalNotification(type: "endSpeaking")
        isConnected2 = false
        NSLog("LOG: Remote participant stopped talking")
    }
    
    // Remote participant left the room
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        NSLog("LOG: remote participant left the room")
        if !isPressing {
            Task {
                await handleParticipantDidDisconnect()
            }
        }
    }

    // handleParticipantDidDisconnect start
    private func handleParticipantDidDisconnect() async {
        isLocked = false
        await unpublishAudio()
        await disconnect()
        
        guard let currentUserId = repoManager?.userRecord?.id,
              let currentUserDeviceToken = repoManager?.userRecord?.deviceToken,
              let roomName = repoManager?.userRecord?.roomName else {
            NSLog("LOG: Missing required user data")
            return
        }
        
        let friendDeviceToken = extractFriendDeviceToken(from: roomName, currentUserDeviceToken: currentUserDeviceToken)
        if friendDeviceToken == nil {
            NSLog("LOG: Unable to extract friend device token")
            return
        }
        
        NSLog("LOG: friendDeviceToken: \(friendDeviceToken!)")
        NSLog("LOG: currentUserId: \(currentUserId)")
        
        do {
            if let friendUser = try await fetchFriendUser(deviceToken: friendDeviceToken!) {
                await updateUserBusyStatus(currentUserId: currentUserId, friendId: friendUser.id)
            } else {
                NSLog("LOG: Could not find user with deviceToken \(friendDeviceToken!)")
            }
        } catch {
            NSLog("LOG: Error fetching friend user data: \(error.localizedDescription)")
        }
    }

    private func extractFriendDeviceToken(from roomName: String, currentUserDeviceToken: String) -> String? {
        let components = roomName.split(separator: "_").map(String.init)
        guard components.count == 2 else { return nil }
        return components[0] == currentUserDeviceToken ? components[1] : components[0]
    }

    private func fetchFriendUser(deviceToken: String) async throws -> UserDto? {
        return try await repoManager?.fetchUserFromFirebase(field: "deviceToken", value: deviceToken)
    }

    private func updateUserBusyStatus(currentUserId: String, friendId: String?) async {
        guard let friendId = friendId else {
            NSLog("LOG: LiveKitManager-updateUserBusyStatus: friendId is nil")
            return
        }
        
        repoManager?.updateUserField(userId: currentUserId, fieldsToUpdate: ["isBusy": false])
        NSLog("LOG: Set current user's isBusy to false")

        repoManager?.updateUserField(userId: friendId, fieldsToUpdate: ["isBusy": false])
        NSLog("LOG: Set friend's isBusy to false")
    }
    // handleParticipantDidDisconnect end


    func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) {
//        NSLog("LOG: LiveKitManager-room-didUnpublishTrack")
//        notificationManager?.sendRemoteNotification(type: "disconnect")
        if let receiverToken = repoManager?.selectedFriend?.deviceToken {
            notificationManager?.sendRemoteNotification(type: "disconnect", receiverToken: receiverToken)
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
}
