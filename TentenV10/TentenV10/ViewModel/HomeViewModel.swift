import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class HomeViewModel: ObservableObject {
    private var firebaseManager = FirebaseManager.shared
    private var databaseManager = DatabaseManager.shared
    
    @Published var userRecord: UserRecord?
}

// MARK: Home View
extension HomeViewModel {
    func fetchUserFromDatabase(currentUserId: String) {
        NSLog("LOG: fetchUserFromDatabase")
        if let userRecord = databaseManager.fetchUser(id: currentUserId) {
            self.userRecord = userRecord
            print(self.userRecord ?? "")
        } else {
            NSLog("LOG: Error fetching user from local database in HomeViewModel")
            restoreLocalDB(userId: currentUserId)
        }
    }

    private func restoreLocalDB(userId: String) {
        let userRef = Firestore.firestore().collection("users").document(userId)
        
        userRef.getDocument { [weak self] document, error in
            if let error = error {
                NSLog("LOG: Error fetching user from Firestore: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                NSLog("LOG: No user found in Firestore with id: \(userId)")
                NSLog("LOG: Signing Out")
                self?.firebaseManager.signOut { result in
                    switch result {
                    case .success:
                        NSLog("LOG: Succeed to signout")
                    case .failure(let error):
                        NSLog("LOG: Failed to signout: \(error.localizedDescription)")
                    }
                }
                return
            }
            
            do {
                let userDto = try document.data(as: UserDto.self)
                self?.fetchProfileImage(userDto: userDto)
            } catch {
                NSLog("LOG: Error decoding UserDto from Firestore: \(error.localizedDescription)")
            }
        }
    }

    private func fetchProfileImage(userDto: UserDto) {
        guard let currentUser = Auth.auth().currentUser else {
            NSLog("LOG: No current user found, unable to fetch profile image.")
            self.saveUserToLocalDatabase(userDto: userDto, profileImageData: nil)
            return
        }

        // Construct the storage path using the user's UID
        let profileImagePath = "profile_images/\(currentUser.uid).jpg"
        let storageRef = Storage.storage().reference().child(profileImagePath)

        NSLog("LOG: Fetching profile image from path: \(profileImagePath)")
        
        storageRef.getData(maxSize: 10 * 1024 * 1024) { [weak self] data, error in
            if let error = error {
                NSLog("LOG: Error fetching profile image from Storage: \(error.localizedDescription)")
                // Proceed with user data without profile image
                self?.saveUserToLocalDatabase(userDto: userDto, profileImageData: nil)
            } else if let data = data {
                // Save user data with profile image
                self?.saveUserToLocalDatabase(userDto: userDto, profileImageData: data)
            }
        }
    }

    private func saveUserToLocalDatabase(userDto: UserDto, profileImageData: Data?) {
        let userRecord = UserRecord(
            id: userDto.id ?? userDto.id ?? "",
            email: userDto.email,
            username: userDto.username,
            pin: userDto.pin,
            hasIncomingCallRequest: userDto.hasIncomingCallRequest,
            profileImageData: profileImageData,
            deviceToken: userDto.deviceToken,
            friends: userDto.friends
        )

        // Update the published userRecord
        self.userRecord = userRecord
        
        // Save to local database
        self.databaseManager.saveUser(user: userRecord)
        
        NSLog("LOG: User fetched and saved from Firestore with profile image: \(userRecord)")
    }
}

// MARK: Add Friend View
extension HomeViewModel {
    func addFriendByPin(currentUserId: String, friendPin: String, completion: @escaping (Result<String, Error>) -> Void) {
        firebaseManager.addFriendByPin(currentUserId: currentUserId, friendPin: friendPin) { [weak self] result in
            switch result {
            case .success(let friendId):
                self?.addFriendToLocalDatabase(currentUserId: currentUserId, friendId: friendId)
                completion(.success(friendId))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func addFriendToLocalDatabase(currentUserId: String, friendId: String) {
        guard var userRecord = self.userRecord else {
            NSLog("LOG: Current user record not found in local database.")
            return
        }

        // Add the friendId to the user's friends list if not already present
        if !userRecord.friends.contains(friendId) {
            userRecord.friends.append(friendId)
            self.userRecord = userRecord
            databaseManager.saveUser(user: userRecord)
            
            NSLog("LOG: Friend added successfully to the local database.")
        } else {
            NSLog("LOG: Error adding friend to user in local database.")
        }
    }
    
    func signOut() {
        FirebaseManager.shared.signOut { result in
            switch result {
            case .success:
                NSLog("LOG: Sign out succeed")
            case .failure(let error):
                NSLog("LOG: Error signing out: \(error.localizedDescription)")
            }
        }
    }

    func updateDeviceTokenInLocalDatabase(userRecord: UserRecord) {
        // Save the updated user record back to the local database
        databaseManager.saveUser(user: userRecord)

        // Update the published userRecord to trigger view update
        self.userRecord = userRecord
    }
}
