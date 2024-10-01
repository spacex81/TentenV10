import Foundation

class NotificationManager {
    static private var _shared: NotificationManager?
    
    // Singleton accessor
    static func shared(repoManager: RepositoryManager, authManager: AuthManager) -> NotificationManager {
        if let instance = _shared {
            return instance
        } else {
            let instance = NotificationManager(repoManager: repoManager, authManager: authManager)
            _shared = instance
            return instance
        }
    }
    
    // Dependencies
    let repoManager: RepositoryManager
    let authManager: AuthManager
    
    private let handleRegularNotificationUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/handleRegularNotification"

    // Private initializer
    private init(repoManager: RepositoryManager, authManager: AuthManager) {
        self.repoManager = repoManager
        self.authManager = authManager
    }

    func sendRemoteNotification(type: String) {
        NSLog("LOG: sendRemoteNotification of type: \(type)")
        if
            let selectedFriend = repoManager.selectedFriend,
            let receiverToken = selectedFriend.deviceToken,
            let senderId = authManager.currentUser?.uid
        {
            guard let url = URL(string: handleRegularNotificationUrl) else {
                NSLog("Failed to create URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonBody: [String: Any] = [
                "receiverToken": receiverToken,
                "notificationType": type,
                "senderId": senderId
            ]
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
                request.httpBody = jsonData
                
                Task {
                    let (_, _) = try await URLSession.shared.data(for: request)
                }
            } catch {
                NSLog("LOG: Error when serializing the json body when sending poke")
            }
        }
    }
}
