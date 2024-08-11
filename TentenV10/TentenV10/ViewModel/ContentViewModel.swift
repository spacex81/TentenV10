import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GRDB

class ContentViewModel: ObservableObject {
    
    @Published var isUserLoggedIn = false
    // used once when app launch
    @Published var needUserFetch = true
    @Published var currentUser: User?
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var selectedImage: UIImage?
    @Published var userRecord: UserRecord? {
        didSet {
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
            
            if let userRecord = self.userRecord {
                listenToUser(userRecord: userRecord)
                listenToFriends(userRecord: userRecord)
            }
        }
    }
    
    @Published var selectedFriend: FriendRecord?
    @Published var detailedFriends: [FriendRecord] = []
    @Published var friendPin: String = ""
    @Published var isListeningToFriends = false 
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false

    
    private var deviceToken: String? {
        didSet {
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
        }
    }
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var friendsListeners: [ListenerRegistration] = []
    private var userListener: ListenerRegistration?
    private var previousUserDto: UserDto?
    
    private let firebaseManager = FirebaseManager.shared
    private let databaseManager = DatabaseManager.shared
    @ObservedObject var liveKitManager = LiveKitManager.shared
    private let audioSessionManager = AudioSessionManager.shared
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    init() {
        startListeningToAuthChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
        
        bindLiveKitManager()
    }
    
    deinit {
        stopListeningToAuthChanges()
        friendsListeners.forEach { $0.remove() }
    }
    
    private func bindLiveKitManager() {
        liveKitManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        liveKitManager.$isPublished
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPublished)
    }

    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
    }
    
    func startListeningToAuthChanges() {
        authStateListenerHandle = firebaseManager.auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    self.isUserLoggedIn = true
                    self.currentUser = user
                } else {
                    self.isUserLoggedIn = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    func stopListeningToAuthChanges() {
        if let handle = authStateListenerHandle {
            firebaseManager.auth.removeStateDidChangeListener(handle)
        }
    }
}

// MARK: LiveKit
extension ContentViewModel {
    func connect() async {
        guard let friendUid = selectedFriend?.id else {
            NSLog("Friend is not selected")
            return
        }
        
        await liveKitManager.connect()
        firebaseManager.updateCallRequest(friendUid: friendUid, hasIncomingCallRequest: true)
    }
    
    func disconnect() {
        guard let friendUid = selectedFriend?.id else {
            NSLog("Friend is not selected")
            return
        }

        Task {
            await liveKitManager.disconnect()
            firebaseManager.updateCallRequest(friendUid: friendUid, hasIncomingCallRequest: false)
        }
    }
    
    func publishAudio() {
        Task {
            await liveKitManager.publishAudio()
        }
    }
    
    func unpublishAudio() async {
        await liveKitManager.unpublishAudio()
    }
}

// MARK: Friend
extension ContentViewModel {
    func addFriend() {
        Task {
            guard var newUserRecord = userRecord else {
                NSLog("LOG: userRecord is nil when adding friend")
                return
            }
        
            do {
                if friendPin != "" {
                     let friendId = try await firebaseManager.getFriendByPin(friendPin: friendPin)
                     
                     if !newUserRecord.friends.contains(friendId) {
                         newUserRecord.friends.append(friendId)
                         
                         DispatchQueue.main.async {
                             self.userRecord!.friends.append(friendId)
                             self.friendPin = ""
                         }
                         self.databaseManager.createUser(user: newUserRecord)
                         self.firebaseManager.addFriendId(friendId: friendId)
                         
                         // fetch detailed friend
                         let friendUserDto = try await self.firebaseManager.fetchUser(userId: friendId)
                         let friendRecord = try await self.convertUserDtoToFriendRecord(userDto: friendUserDto)
                         
                         if !self.detailedFriends.contains(friendRecord) {
                             DispatchQueue.main.async {
                                 self.detailedFriends.append(friendRecord)
                             }
                             self.databaseManager.createFriend(friend: friendRecord)
                         } else {
                             NSLog("LOG: friend is already added-FriendRecord")
                         }
                     } else {
                         NSLog("LOG: friend is already added-FriendID")
                     }
                 } else {
                     throw NSError(domain: "addFriendError", code: -1, userInfo: [NSLocalizedDescriptionKey: "friendPin is not set when trying to add friend by pin"])
                 }
            } catch {
                NSLog("LOG: Error adding friend by pin: \(error.localizedDescription)")
            }
        }
    }
    
    
    func listenToFriends(userRecord: UserRecord) {
        NSLog("LOG: listenToFriends")
        let friends = userRecord.friends

        // Clear existing listeners before setting up new ones
        friendsListeners.forEach { $0.remove() }
        friendsListeners = []

        // Listen to each friend
        friends.forEach { listenToFriend(friendId: $0) }
    }
    
    func listenToUser(userRecord: UserRecord) {
        let userId = userRecord.id
        userListener = firebaseManager.usersCollection.document(userId).addSnapshotListener {
            [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
               print("Error listening to user: \(error.localizedDescription)")
               return
            }
            
            if let document = document, document.exists {
                Task {
                    do {
                        let userDto = try document.data(as: UserDto.self)
                        
                        self.handleIncomingCallRequest(oldDto: self.previousUserDto, newDto: userDto)
                        self.previousUserDto = userDto
                        
                        let userRecord = try await self.convertUserDtoToUserRecord(userDto: userDto)
                        
                        if self.userRecord != userRecord {
                            NSLog("LOG: new user record!")
                            DispatchQueue.main.async {
                                self.userRecord = userRecord
                            }
                            self.databaseManager.createUser(user: userRecord)
                        }
                    } catch {
                        print("Error converting UserDto to UserRecord: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Document does not exist when trying to listen to user")
            }
        }
    }
    
    private func handleIncomingCallRequest(userDto: UserDto) {
        NSLog("LOG: handleIncomingCallRequest")
        if userDto.hasIncomingCallRequest {
            Task {
                await liveKitManager.connect()
            }
        } else {
            Task {
                await liveKitManager.disconnect()
            }
        }
    }

    func listenToFriend(friendId: String) {
        let friendListener = firebaseManager.usersCollection.document(friendId).addSnapshotListener { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening to friend: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                Task {
                    do {
                        let friendDto = try document.data(as: UserDto.self)
                        let friendRecord = try await self.convertUserDtoToFriendRecord(userDto: friendDto)
                        
                        DispatchQueue.main.async {
                            if let index = self.detailedFriends.firstIndex(where: { $0.id == friendRecord.id }) {
                                self.detailedFriends[index] = friendRecord
                            } else {
                                self.detailedFriends.append(friendRecord)
                            }
                        }
                        self.databaseManager.createFriend(friend: friendRecord)

                    } catch {
                        print("Error converting UserDto to FriendRecord: \(error.localizedDescription)")
                    }
                }
            } else {
                print("Document does not exist for friendId: \(friendId)")
            }
        }

        friendsListeners.append(friendListener)
    }
    
    func selectFriend(friend: FriendRecord) {
        DispatchQueue.main.async {
            self.selectedFriend = friend
        }
    }
}

// MARK: User
extension ContentViewModel {
    func fetchUserFromLocal(id: String) -> UserRecord? {
        let newUserRecord = databaseManager.readUser(id: id)
        return newUserRecord
    }
    
    func fetchUserFromRemote(id: String) async throws -> UserRecord {
        do {
            let newUserDto = try await firebaseManager.fetchUser(userId: id)
            let newUserRecord = try await convertUserDtoToUserRecord(userDto: newUserDto)
            return newUserRecord
        } catch {
            NSLog("LOG: Error fetching user from Firestore: \(error.localizedDescription)")
            self.signOut()
            throw NSError(domain: "fetchUserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user from remote firestore."])
        }
    }
    
    func fetchUser(id: String) async throws {
        var newUserRecord: UserRecord?
        var needToUpdateLocal = false
        
        NSLog("LOG: Fetching user from local database")
        newUserRecord = fetchUserFromLocal(id: id)
        if newUserRecord == nil {
            needToUpdateLocal = true
            NSLog("LOG: Local database doesn't have user record")
            NSLog("LOG: Fetching user from remote firestore")
            newUserRecord = try await fetchUserFromRemote(id: id)
        }
        
        if let newUserRecord = newUserRecord {
            DispatchQueue.main.async {
                self.userRecord = newUserRecord
            }
            if needToUpdateLocal {
                databaseManager.createUser(user: newUserRecord)
                needToUpdateLocal = false
            }
            
            // fetch detailedFriends by userId
            NSLog("LOG: Fetching detailedFriends from local database")
            let newDetailedFriends = databaseManager.fetchFriendsByUserId(userId: newUserRecord.id)
            if newDetailedFriends.isEmpty {
                NSLog("LOG: detailedFriends in local database is empty")
                NSLog("LOG: Fetching detailedFriends from remote firestore")
                for friendId in newUserRecord.friends {
                    NSLog("LOG: newUserRecord.friends: \(newUserRecord.friends)")
                    fetchFriendAndUpdateLocal(friendId: friendId)
                }
            }
            DispatchQueue.main.async {
                self.detailedFriends = newDetailedFriends
            }
            NSLog("LOG: newDetailedFriends: \(newDetailedFriends)")
        } else {
            NSLog("LOG: Remote firestore doesn't have user record either")
            throw NSError(domain: "signIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Either local or remote doesn't have user record whent fetching user"])
        }
    }
    
    private func fetchFriendAndUpdateLocal(friendId: String) {
        Task {
            do {
                let friendUserDto = try await firebaseManager.fetchUser(userId: friendId)
                let friendRecord = try await convertUserDtoToFriendRecord(userDto: friendUserDto)
                if !self.detailedFriends.contains(friendRecord) {
                    DispatchQueue.main.async {
                        self.detailedFriends.append(friendRecord)
                    }
                    self.databaseManager.createFriend(friend: friendRecord)
                }
            } catch {
                NSLog("LOG: Error while fetching friend from firestore: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: Auth
extension ContentViewModel {
    func signIn() {
        DispatchQueue.main.async {
            self.needUserFetch = false
        }
        Task {
            do {
                let user = try await firebaseManager.signIn(email: email, password: password)
                try await fetchUser(id: user.uid)
            } catch {
                NSLog("Failed to sign in: \(error.localizedDescription)")
            }
        }
    }
    
    func signUp() {
        DispatchQueue.main.async {
            self.needUserFetch = false
        }
        Task {
            do {
                let user = try await firebaseManager.signUp(email: email, password: password)
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
                
                DispatchQueue.main.async {
                    self.userRecord = newUserRecord
                }
                
                databaseManager.createUser(user: newUserRecord)
                
                let profileImagePath = try await firebaseManager.uploadImage(id: id, profileImageData: profileImageData)
                let newUserDto = UserDto(id: id, email: email, username: username, pin: pin, profileImagePath: profileImagePath, deviceToken: deviceToken)
                firebaseManager.createUser(userDto: newUserDto)
                
            } catch {
                NSLog("Error signing up user: \(error.localizedDescription)")
            }
        }
    }
    
    func signOut() {
        NSLog("LOG: signOut")
        DispatchQueue.main.async {
            self.userRecord = nil
            self.detailedFriends = []
        }
        firebaseManager.signOut()
    }
}

// MARK: Utils
extension ContentViewModel {
    private func generatePin() -> String {
            let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
            return String((0..<7).map { _ in letters.randomElement()! })
    }
    
    private func convertUserDtoToUserRecord(userDto: UserDto) async throws -> UserRecord {
        guard let profileImagePath = userDto.profileImagePath else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile image path is not set."])
        }
        
        let storageRef = firebaseManager.storage.reference(forURL: profileImagePath)
        let imageData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    NSLog("LOG: Error getting image data from profileImagePath: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while fetching image data."]))
                }
            }
        }
        
        let userRecord = UserRecord(
            id: userDto.id ?? UUID().uuidString,
            email: userDto.email,
            username: userDto.username,
            pin: userDto.pin,
            hasIncomingCallRequest: userDto.hasIncomingCallRequest,
            profileImageData: imageData,
            deviceToken: userDto.deviceToken,
            friends: userDto.friends
        )
        
        return userRecord
    }
    
    private func convertUserDtoToFriendRecord(userDto: UserDto) async throws -> FriendRecord {
        guard let profileImagePath = userDto.profileImagePath else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile image path is not set."])
        }
        
        let storageRef = firebaseManager.storage.reference(forURL: profileImagePath)
        let imageData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    NSLog("LOG: Error getting image data from profileImagePath: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while fetching image data."]))
                }
            }
        }
        guard let userId = self.currentUser?.uid else {
            NSLog("LOG: currentUserId is not set when converting userDto into friendRecord")
            throw NSError(domain: "convertUserDtoToFriendRecord", code: -1, userInfo: [NSLocalizedDescriptionKey: "currentUser is null when converting UserDto to FriendRecord"])
        }
        
        let friendRecord = FriendRecord(
            id: userDto.id ?? UUID().uuidString,
            email: userDto.email,
            username: userDto.username,
            pin: userDto.pin,
            profileImageData: imageData,
            deviceToken: userDto.deviceToken,
            userId: userId
        )
        
        return friendRecord
    }

    
    private func updateDeviceToken(oldUserRecord: UserRecord, newDeviceToken: String) {
        NSLog("LOG: updateDeviceToken")
        var newUserRecord = oldUserRecord
        newUserRecord.deviceToken = newDeviceToken

        // update device token in self.userRecord
        DispatchQueue.main.async {
            self.userRecord = newUserRecord
        }
        // update local database
        databaseManager.createUser(user: newUserRecord)
        // update firestore
        firebaseManager.updateDeviceToken(userId: newUserRecord.id, newDeviceToken: newDeviceToken)
    }
    
    private func handleIncomingCallRequest(oldDto: UserDto?, newDto: UserDto) {
        guard let oldDto = oldDto else {
            NSLog("LOG: No previous UserDto to compare.")
            return
        }

        if oldDto.hasIncomingCallRequest != newDto.hasIncomingCallRequest {
//            NSLog("LOG: UserDto hasIncomingCallRequest changed from \(oldDto.hasIncomingCallRequest) to \(newDto.hasIncomingCallRequest)")
            if newDto.hasIncomingCallRequest {
                Task {
                    await liveKitManager.connect()
                }
            } else {
                Task {
                    await liveKitManager.disconnect()
                }
            }
        }
    }
}

extension ContentViewModel {
    func handleScenePhaseChange(to newScenePhase: ScenePhase) {
        switch newScenePhase {

        case .active:
             NSLog("LOG: App is active and in the foreground")
            backgroundTaskManager.stopAudioTask()

        case .inactive:
            NSLog("LOG: App is inactive")

        case .background:
            NSLog("LOG: App is in the background")
            audioSessionManager.setupAudioPlayer()
            backgroundTaskManager.startAudioTask()

        @unknown default:
            break
        }
    }
}
