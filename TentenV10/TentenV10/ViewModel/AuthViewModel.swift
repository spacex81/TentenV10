import Foundation
import UIKit

class AuthViewModel: ObservableObject {
    private let authManager = AuthManager.shared
    private let repoManager = RepositoryManager.shared
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var selectedImage: UIImage?
    
    @Published var deviceToken: String?
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)

    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
    }
}

extension AuthViewModel {
    func signIn() {
        // Check if user logged in with same account
        if let _ = repoManager.readUserFromDatabase(email: email) {
            DispatchQueue.main.async {
                self.repoManager.needUserFetch = false
            }
        } else {
            // If user logged in with different account than set 'needUserFetch' to true
            // erase current content of user table and friend table
            repoManager.userRecord = nil
            repoManager.detailedFriends = []
            repoManager.selectedFriend = nil
            repoManager.removeAllListeners()
            repoManager.eraseAllUsers()
            repoManager.eraseAllFriends()
            DispatchQueue.main.async {
                self.repoManager.needUserFetch = true
            }
            
        }
        
        Task {
            do {
                let user = try await authManager.signIn(email: email, password: password)
                try await repoManager.fetchUser(id: user.uid)
            } catch {
                NSLog("Failed to sign in: \(error.localizedDescription)")
            }
        }
    }
    
    func signUp() {
        DispatchQueue.main.async {
            self.repoManager.needUserFetch = false
        }
        Task {
            do {
                let user = try await authManager.signUp(email: email, password: password)
                let id = user.uid
                guard let email = user.email else {
                    NSLog("LOG: firebase auth user doesn't have email info")
                    return
                }
                let username = email.split(separator: "@").first.map(String.init) ?? "User"
                let pin = generatePin()
                guard let selectedImage = self.selectedImage else {
                    NSLog("LOG: profile image is not set")
                    return
                }
                guard let profileImageData = selectedImage.jpegData(compressionQuality: 0.8) else {
                    NSLog("LOG: Error converting UIImage to Data")
                    return
                }
                
                let newUserRecord = UserRecord(id: id, email: email, username: username, pin: pin, profileImageData: profileImageData, deviceToken: deviceToken)
                
                // TODO: move to RepositoryManager
                await repoManager.createUserWhenSignUp(newUserRecord: newUserRecord)
            } catch {
                NSLog("Error signing up user: \(error.localizedDescription)")
            }
        }
    }
    
    func signOut() {
        NSLog("LOG: signOut")
        DispatchQueue.main.async {
            self.repoManager.userRecord = nil
            self.repoManager.detailedFriends = []
        }
        authManager.signOut()
    }
}

// MARK: Utils
extension AuthViewModel {
    private func generatePin() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<7).map { _ in letters.randomElement()! })
    }
}
