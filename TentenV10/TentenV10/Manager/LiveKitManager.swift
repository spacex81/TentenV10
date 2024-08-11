import Foundation
import LiveKit

class LiveKitManager: ObservableObject, RoomDelegate {
    static let shared = LiveKitManager()
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false
    
    var room: Room?

    let livekitUrl = "wss://tentwenty-bp8gb2jg.livekit.cloud"
    let handleLiveKitTokenUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/handleLivekitToken"
    let handleRegularNotificationUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/handleRegularNotification"

    var roomName: String = "testName"
    
    init() {
        let roomOptions = RoomOptions(adaptiveStream: true, dynacast: true)
        room = Room(delegate: self, roomOptions: roomOptions)
    }
}

extension LiveKitManager {
    func connect() async {
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
            DispatchQueue.main.async {
                self.isPublished = true
            }
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
