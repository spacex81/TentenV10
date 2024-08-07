import Foundation
import UIKit
import Combine
import FirebaseAuth
import GRDB

class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var user: User?
//    @Published var userRecord: UserRecord?
    
    private var deviceToken: String?
    let pin: String

    private var cancellables = Set<AnyCancellable>()
    
    init() {
        pin = AuthViewModel.generatePin()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)

        _ = Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
//            self.firebaseManager.deviceToken = token
        }
    }

    func signIn() {
        FirebaseManager.shared.signIn(email: email, password: password) { result in
            switch result {
            case .success(let authResult):
                self.user = authResult.user
                self.errorMessage = nil
//                self.saveUserToDatabase(user: authResult.user)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func signUp(profileImage: UIImage?) {
        FirebaseManager.shared.signUp(email: email, password: password) { result in
            switch result {
            case .success(let authResult):
                self.user = authResult.user
                self.errorMessage = nil
                // save user profile in local database
                self.saveUserToDatabase(user: authResult.user, profileImage: profileImage)
                
                // save user profile in firebase
                if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.8) {
                    FirebaseManager.shared.uploadProfileImage(uid: authResult.user.uid, imageData: imageData) { result in
                        switch result {
                        case .success(let url):
                            self.saveUserToFirestore(user: authResult.user, profileImageUrl: url.absoluteString)
                        case .failure(let error):
                            print("Error uploading profile image: \(error)")
                            self.saveUserToFirestore(user: authResult.user, profileImageUrl: nil)
                        }
                    }
                } else {
                    // No profile image, just save the user to Firestore
                    self.saveUserToFirestore(user: authResult.user, profileImageUrl: nil)
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func saveUserToDatabase(user: FirebaseAuth.User, profileImage: UIImage? = nil) {
        NSLog("LOG: saveUserToDatabase")
        guard let profileImage = profileImage else {
            NSLog("LOG: profileImage is not set")
            return
        }
        
        let profileImageData = profileImage.jpegData(compressionQuality: 0.8)
        NSLog("LOG: Saving image data of \(profileImageData?.count ?? 0) bytes")


        let username = email.split(separator: "@").first.map(String.init) ?? "User"
//        let userRecord = UserRecord(id: user.uid, email: user.email ?? "", username: username, profileImageData: profileImageData, deviceToken: deviceToken)
        let userRecord = UserRecord(id: user.uid, email: user.email ?? "", username: username, pin: pin, profileImageData: profileImageData, deviceToken: deviceToken)
        NSLog("LOG: userRecord: \(userRecord)")
        DatabaseManager.shared.saveUser(user: userRecord)
    }

    private func saveUserToFirestore(user: FirebaseAuth.User, profileImageUrl: String?) {
        let username = email.split(separator: "@").first.map(String.init) ?? "User"

//        let userDto = UserDto(id: user.uid, email: user.email ?? "", displayName: user.displayName, profileImagePath: profileImageUrl, deviceToken: deviceToken)
        let userDto = UserDto(id: user.uid, email: user.email ?? "", username: username, pin: pin, profileImagePath: profileImageUrl, deviceToken: deviceToken)
        
        // Save to Firestore. Move this code to FirebaseManager
        do {
            try FirebaseManager.shared.db.collection("users").document(user.uid).setData(from: userDto)
        } catch {
            print("Error saving user to Firestore: \(error)")
        }
    }
    
//    func fetchUserFromDatabase(userID: String) {
//        NSLog("LOG: fetchUserFromDatabase")
//        if let userRecord = DatabaseManager.shared.fetchUser(id: userID) {
//            self.userRecord = userRecord
//        }
//    }

    func signOut() {
        FirebaseManager.shared.signOut { result in
            switch result {
            case .success:
                self.user = nil
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    static func generatePin() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<7).map { _ in letters.randomElement()! })
    }
}
