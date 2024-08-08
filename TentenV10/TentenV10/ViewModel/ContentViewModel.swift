import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GRDB

class ContentViewModel: ObservableObject {
    
    @Published var isUserLoggedIn = false
    @Published var currentUserId: String?
    @Published var selectedImage: UIImage?
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var friendPin: String = ""
    @Published var userRecord: UserRecord? {
        didSet {
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
        }
    }
    @Published var detailedFriends: [FriendRecord] = []
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var deviceToken: String? {
        didSet {
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
        }
    }
    
    private func updateDeviceToken(oldUserRecord: UserRecord, newDeviceToken: String) {
        NSLog("LOG: updateDeviceToken")
        var newUserRecord = oldUserRecord
        newUserRecord.deviceToken = newDeviceToken

        // update device token in self.userRecord
        self.userRecord = newUserRecord
        // update local database
        databaseManager.createUser(user: newUserRecord)
        // update firestore
        firebaseManager.updateDeviceToken(userId: newUserRecord.id, newDeviceToken: newDeviceToken)
    }
    
    private let firebaseManager = FirebaseManager.shared
    private let databaseManager = DatabaseManager.shared
    
    init() {
        startListeningToAuthChanges()
    }
    
    deinit {
        stopListeningToAuthChanges()
    }
    
    func startListeningToAuthChanges() {
        authStateListenerHandle = firebaseManager.auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                isUserLoggedIn = true
                currentUserId = user.uid
            } else {
                isUserLoggedIn = false
                currentUserId = nil
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
    }
    
    func stopListeningToAuthChanges() {
        if let handle = authStateListenerHandle {
            firebaseManager.auth.removeStateDidChangeListener(handle)
        }
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
    }
    
    func fetchUser() {
        if let id = currentUserId {
            NSLog("LOG: Fetching user from database")
            let userRecord = databaseManager.readUser(id: id)
            if let userRecord = userRecord {
                // set memory
                self.userRecord = userRecord
                // set local db
                self.databaseManager.createUser(user: userRecord)
            } else {
                NSLog("LOG: user record is not available in local database")
                NSLog("LOG: Fetching user from firestore")
                firebaseManager.fetchUser(userId: id) { userDto in
                    self.convertUserDtoToUserRecord(userDto: userDto) { userRecord in
                        // set memory
                        self.userRecord = userRecord
                        // set local db
                        self.databaseManager.createUser(user: userRecord)
                    }
                }
            }
        }
    }
    
}

// MARK: Friend
extension ContentViewModel {
    func addFriend() {
        guard var newUserRecord = userRecord else {
            NSLog("LOG: userRecord is nil when adding friend")
            return
        }
        
        // check if friend corresponding to friendPin exists
        firebaseManager.getFriendIdByPin(friendPin: self.friendPin) { friendId in
            if !newUserRecord.friends.contains(friendId) {
                // add friend id in user record
                newUserRecord.friends.append(friendId)
                self.userRecord = newUserRecord
                self.databaseManager.createUser(user: newUserRecord)
                self.firebaseManager.addFriendId(friendId: friendId)

                // fetch user dto from firestore
                self.firebaseManager.fetchUser(userId: friendId) { userDto in
                    // convert user dto to friend record
                    self.convertUserDtoToFriendRecord(userDto: userDto) { friendRecord in
                     // add friend record in memory
                        self.detailedFriends.append(friendRecord)
                     // add friend record in local database
                        self.databaseManager.createFriend(friend: friendRecord)
                    }
                }

            }
        }
        
    }
}

// MARK: Auth
extension ContentViewModel {
    func signIn() {
        firebaseManager.signIn(email: email, password: password)
   }
    
    func signUp() {
        firebaseManager.signUp(email: email, password: password) { result in
            let id = result.user.uid
            guard let email = result.user.email else {
                NSLog("LOG: email is nil")
                return
            }
            let username = email.split(separator: "@").first.map(String.init) ?? "User"
            let pin = self.generatePin()
            guard let selectedImage = self.selectedImage else {
                NSLog("LOG: profile image is not set")
                return
            }
            guard let profileImageData = selectedImage.jpegData(compressionQuality: 0.8) else {
                NSLog("LOG: profile image data is not set")
                return
            }
            
            let userRecord = UserRecord(id: id, email: email, username: username, pin: pin, profileImageData: profileImageData, deviceToken: self.deviceToken)
            
            // set memory
            self.userRecord = userRecord
            // set db
            self.databaseManager.createUser(user: userRecord)
            // set remote
            self.firebaseManager.uploadImage(id: id, profileImageData: profileImageData) { url in
                let profileImagePath = url
                let userDto = UserDto(id: id,email: email, username: username, pin: pin, profileImagePath: profileImagePath)
                self.firebaseManager.createUser(userDto: userDto)
            }
        }
    }
    
    func signOut() {
        firebaseManager.signOut()
    }
}

// MARK: Utils
extension ContentViewModel {
    private func generatePin() -> String {
            let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
            return String((0..<7).map { _ in letters.randomElement()! })
    }
    
    func convertUserDtoToFriendRecord(userDto: UserDto, completion: @escaping (FriendRecord) -> Void) {
        guard let profileImagePath = userDto.profileImagePath else {
            NSLog("LOG: profileImagePath is not set")
            return
        }
        
        let storageRef = firebaseManager.storage.reference(forURL: profileImagePath)
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                NSLog("LOG: Error getting image data from profileImagePath: \(error.localizedDescription)")
            } else {
                guard let userId = self.currentUserId else {
                    NSLog("LOG: currentUserId is not set when converting userDto into friendRecord")
                    return
                }
                
                let friendRecord = FriendRecord(id: userDto.id!, email: userDto.email, username: userDto.username, pin: userDto.pin, profileImageData: data, userId: userId)
                completion(friendRecord)
            }
        }
    }
    
     func convertUserDtoToUserRecord(userDto: UserDto, completion: @escaping (UserRecord) -> Void) {
        guard let profileImagePath = userDto.profileImagePath else {
            NSLog("LOG: profileImagePath is not set")
            return
        }
        
        let storageRef = firebaseManager.storage.reference(forURL: profileImagePath)
        storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
            if let error = error {
                NSLog("LOG: Error getting image data from profileImagePath: \(error.localizedDescription)")
            } else {
                let userRecord = UserRecord(
                    id: userDto.id ?? UUID().uuidString,
                    email: userDto.email,
                    username: userDto.username,
                    pin: userDto.pin,
                    hasIncomingCallRequest: userDto.hasIncomingCallRequest,
                    profileImageData: data,
                    deviceToken: userDto.deviceToken,
                    friends: userDto.friends
                )
                completion(userRecord)
            }
        }
    }
   
}

enum UserConversionError: Error {
    case missingProfileImagePath
    case imageDownloadFailed
}
