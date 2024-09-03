import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GRDB

class RepositoryManager: ObservableObject {
    static let shared = RepositoryManager()
    
    private let liveKitManager = LiveKitManager.shared
    weak var collectionViewController: CustomCollectionViewController?
    
    // Local Database
    private var dbQueue: DatabaseQueue!
    
    // Firebase
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    let usersCollection: CollectionReference
    let roomsCollection: CollectionReference
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var roomsListeners: [ListenerRegistration] = []
    private var friendsListeners: [ListenerRegistration] = []
    private var userListener: ListenerRegistration?
    
    private var previousState: UserState = .idle
    
    @Published var currentState: UserState = .idle {
        didSet {
            // Check if the state has changed from .isListening to .idle
            if previousState == .isListening && currentState == .idle {
                // Reload data only when transitioning from .isListening to .idle
                collectionViewController?.reloadData()
            } else if currentState == .isListening {
                // When transitioning to .isListening, update the collection view
                collectionViewController?.reloadData()
            }
            
            // Update the previousState to the current state
            previousState = currentState
        }
    }
    
    @Published var userRecord: UserRecord? {
        didSet {
            
            if let userRecord = self.userRecord {
                // update deviceToken
                if let deviceToken = deviceToken {
                    if userRecord.deviceToken != deviceToken {
//                        NSLog("LOG: updateDeviceToken in userRecord-didSet")
                        updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                    }
                }
                
                // setup listener
                if userListener == nil {
                    listenToUser(userRecord: userRecord)
                }
                if friendsListeners.isEmpty {
                    listenToFriends(userRecord: userRecord)
                }
                if roomsListeners.isEmpty {
                    listenToRooms(userRecord: userRecord)
                }
                
                // update room name
                if let senderToken = userRecord.deviceToken,
                   let receiverToken = selectedFriend?.deviceToken {
                    
                    let tokens = [senderToken, receiverToken].sorted()
                    let roomName = "\(tokens[0])_\(tokens[1])"
                    
                    if userRecord.roomName != roomName {
                         updateRoomName(roomName: roomName)
                    }            
                }
            }
        }
    }
    
    @Published var selectedFriend: FriendRecord? {
        didSet {
            // update room name
            if let senderToken = userRecord?.deviceToken,
               let receiverToken = selectedFriend?.deviceToken {
                let tokens = [senderToken, receiverToken].sorted()
                let roomName = "\(tokens[0])_\(tokens[1])"
                
                if userRecord?.roomName != roomName {
                     updateRoomName(roomName: roomName)
                }
            }
        }
    }
    
    private func updateRoomName(roomName: String) {
//        NSLog("LOG: updateRoomName")
        guard var newUserRecord = userRecord else {
            NSLog("LOG: userRecord is not set when trying to update room name")
            return
        }
        
        newUserRecord.roomName = roomName
        // update memory
        DispatchQueue.main.async {
            self.userRecord = newUserRecord
        }
        // update local db
        createUserInDatabase(user: newUserRecord)
        // not gonna update firebase value here
        // firebase roomName value will be updated only once when connecting to LiveKit
    }
    
    @Published var deviceToken: String? {
        didSet {
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
//                    NSLog("LOG: updateDeviceToken in deviceToken-didSet")
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
        }
    }
    
    @Published var userDto: UserDto?
    @Published var detailedFriends: [FriendRecord] = [] {
        didSet {
//            NSLog("LOG: detailedFriends-didSet")
//            print(detailedFriends)
            // Select friend when app launch
            if detailedFriends.count > 0 && selectedFriend == nil {
                NSLog("LOG: Initial friend is selected")
                self.selectedFriend = detailedFriends[0]
            }
        }
    }
    
    @Published var needUserFetch = true
    
    @Published var currentUser: User?

    init() {
        usersCollection = db.collection("users")
        roomsCollection = db.collection("rooms")
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
        setupDatabase()
        startListeningToAuthChanges()
        
        liveKitManager.repoManager = self
    }
    
    deinit {
        stopListeningToAuthChanges()
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
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
        createUserInDatabase(user: newUserRecord)
        // update firestore
        updateDeviceTokenInFirebase(userId: newUserRecord.id, newDeviceToken: newDeviceToken)
    }
    
    func startListeningToAuthChanges() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let user = user {
                    self.currentUser = user
                    NSLog("self.currentUser is set")
                } else {
                    self.currentUser = nil
                    NSLog("self.currentUser is nil")
                }
            }
        }
    }
    
    func stopListeningToAuthChanges() {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    private func setupDatabase() {
        do {
            let databaseURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("db.sqlite")
            
            dbQueue = try DatabaseQueue(path: databaseURL.path)

            // Register migrations
            var migrator = DatabaseMigrator()

            // v1: Initial database setup, including 'lastInteraction' in 'friends' table
            migrator.registerMigration("v1") { db in
                // Create the users table
                try db.create(table: "users") { t in
                    t.column("id", .text).primaryKey()
                    t.column("email", .text).notNull()
                    t.column("username", .text).notNull()
                    t.column("pin", .text).notNull()
                    t.column("hasIncomingCallRequest", .boolean).notNull().defaults(to: false)
                    t.column("profileImageData", .blob)
                    t.column("deviceToken", .text)
                    t.column("friends", .text)
                    t.column("roomName", .text).notNull().defaults(to: "testRoom")
                    t.column("isBusy", .boolean).notNull().defaults(to: false)
                }
                
                // Create the friends table with 'lastInteraction' column
                try db.create(table: "friends") { t in
                    t.column("id", .text).primaryKey()
                    t.column("email", .text).notNull()
                    t.column("username", .text).notNull()
                    t.column("pin", .text).notNull()
                    t.column("profileImageData", .blob)
                    t.column("deviceToken", .text)
                    t.column("userId", .text).notNull().references("users", onDelete: .cascade) // Foreign key reference to users
                    t.column("isBusy", .boolean).notNull().defaults(to: false)
                    t.column("lastInteraction", .datetime)
                }
            }

            // Migrate the database to the latest version
            try migrator.migrate(dbQueue)
        } catch {
            NSLog("LOG: Error setting up database: \(error)")
        }
    }
}

// MARK: Utils
extension RepositoryManager {
        func sortDetailedFriends() {
        detailedFriends.sort { (friend1, friend2) -> Bool in
            if let lastInteraction1 = friend1.lastInteraction, let lastInteraction2 = friend2.lastInteraction {
                // Both have non-nil lastInteraction, sort by date descending
                return lastInteraction1 > lastInteraction2
            } else if friend1.lastInteraction != nil && friend2.lastInteraction == nil {
                // friend1 has non-nil lastInteraction, friend2 has nil, friend1 comes first
                return true
            } else if friend1.lastInteraction == nil && friend2.lastInteraction != nil {
                // friend1 has nil lastInteraction, friend2 has non-nil, friend2 comes first
                return false
            } else {
                // Both have nil lastInteraction, maintain current order
                return false
            }
        }
    }
}

// MARK: Listener
extension RepositoryManager {
    func listenToRooms(userRecord: UserRecord) {
        let friends = userRecord.friends
        
        roomsListeners.forEach { $0.remove() }
        roomsListeners = []
        
        friends.forEach { friendId in
            let roomId = RoomDto.generateRoomId(userId1: userRecord.id, userId2: friendId)
            listenToRoom(roomId: roomId)
        }
    }
    func listenToFriends(userRecord: UserRecord) {
//        NSLog("LOG: listenToFriends")
        let friends = userRecord.friends

        // Clear existing listeners before setting up new ones
        friendsListeners.forEach { $0.remove() }
        friendsListeners = []

        // Listen to each friend
        friends.forEach { listenToFriend(friendId: $0) }
    }
    
    func listenToUser(userRecord: UserRecord) {
//        NSLog("LOG: listenToUser")
         let userId = userRecord.id
         userListener = usersCollection.document(userId).addSnapshotListener {
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
                         
                         if self.userRecord?.hasIncomingCallRequest != userDto.hasIncomingCallRequest {
                             self.handleIncomingCallRequest(userDto: userDto)
                         }
                         
                         let userRecord = try await self.convertUserDtoToUserRecord(userDto: userDto)
                         
                         if self.userRecord != userRecord {
                             DispatchQueue.main.async {
                                 self.userRecord = userRecord
                             }
                             self.createUserInDatabase(user: userRecord)
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
        let roomName = userDto.roomName
//        NSLog("LOG: handleIncomingCallRequest")
//        NSLog("LOG: room name: \(roomName)")
        
        if userDto.hasIncomingCallRequest {
            Task {
                await liveKitManager.connect(roomName: roomName)
            }
        } else {
            Task {
                await liveKitManager.disconnect()
            }
        }
    }
    
    func listenToRoom(roomId: String) {
        NSLog("LOG: listenToRoom")
        let roomListener = roomsCollection.document(roomId).addSnapshotListener { [weak self] document, error in
            guard let self = self else { return }
            guard let userRecord = self.userRecord else {
                NSLog("LOG: userRecord is not set when trying to use it in room listener")
                return
            }

            if let error = error {
                NSLog("LOG: Error listening to room: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                Task {
                    do {
                        let roomDto = try document.data(as: RoomDto.self)
                        let friendId = roomDto.getFriendId(currentUserId: userRecord.id)
                        
                        // Find the friend in detailedFriends
                        if let index = self.detailedFriends.firstIndex(where: { $0.id == friendId }) {
                            let currentLastInteraction = self.detailedFriends[index].lastInteraction
                            let newLastInteraction = roomDto.lastInteraction.dateValue()
                            
                            // Update only if the lastInteraction value has changed
                            if currentLastInteraction != newLastInteraction {
                                // Update timestamp value in detailedFriends
                                self.detailedFriends[index].lastInteraction = newLastInteraction
                                
                                NSLog("LOG: Sort new detailedFriends")
                                // Sort new detailedFriends
                                self.sortDetailedFriends()
                                await self.collectionViewController?.reloadData()
                                
                                // Reposition center cell to first friend
                                if self.detailedFriends.count > 0 {
//                                    NSLog("LOG: Center first cell")
                                    await self.collectionViewController?.centerCell(at: IndexPath(item: 1, section: 0))
                                    DispatchQueue.main.async {
                                         self.selectedFriend = self.detailedFriends[0]
                                    }
                                }

                                
                                // Save the updated friend record to the database
                                let updatedFriend = self.detailedFriends[index]
                                self.createFriendInDatabase(friend: updatedFriend)
                                

                                // Notify the view model or UI to refresh if necessary
                                DispatchQueue.main.async {
                                    self.objectWillChange.send()
                                }
                            }
                        } else {
//                            NSLog("LOG: Friend with ID \(String(describing: friendId)) not found in detailedFriends")
                        }
                    } catch {
                        NSLog("LOG: Error decoding roomDto: \(error.localizedDescription)")
                    }
                }
            }
        }
        roomsListeners.append(roomListener)
    }

    
    func listenToFriend(friendId: String) {
        let friendListener = usersCollection.document(friendId).addSnapshotListener { [weak self] document, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening to friend: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                Task {
                    do {
                        let friendDto = try document.data(as: UserDto.self)
                        let newFriendRecord = try await self.convertUserDtoToFriendRecord(userDto: friendDto)
                        
                        DispatchQueue.main.async {
                            if let index = self.detailedFriends.firstIndex(where: { $0.id == newFriendRecord.id }) {
                                self.detailedFriends[index] = newFriendRecord
                            } else {
                                self.detailedFriends.append(newFriendRecord)
                            }
                        }
                        self.createFriendInDatabase(friend: newFriendRecord)

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
}

extension RepositoryManager {
    func addFriend(friendPin: String) async {
            guard var newUserRecord = userRecord else {
                NSLog("LOG: userRecord is nil when adding friend")
                return
            }
        
            do {
                if !friendPin.isEmpty {
                     let friendId = try await getFriendByPinFromFirebase(friendPin: friendPin)
                    
                     if !newUserRecord.friends.contains(friendId) {
                         
                         let currentTimestamp = Date()
                         // fetch detailed friend
                         let friendUserDto = try await fetchUserFromFirebase(userId: friendId)

                         newUserRecord.friends.append(friendId)
                         
                         // Part1
                         // Storing user information
                         DispatchQueue.main.async {
                             self.userRecord!.friends.append(friendId)
                         }
                         createUserInDatabase(user: newUserRecord)
                         addFriendIdInFirebase(friendId: friendId)
                         
                         // Part2
                         // Storing room information
                         let roomId = RoomDto.generateRoomId(userId1: newUserRecord.id, userId2: friendId)
                         
                         let roomDocRef = db.collection("rooms").document(roomId)
                         
                         let roomDoc = try await roomDocRef.getDocument()
                         
                         if roomDoc.exists {
                             // Room exists, update the lastInteraction timestamp
                             var roomDto = try roomDoc.data(as: RoomDto.self)
                             roomDto.lastInteraction = Timestamp(date: currentTimestamp)
                             
                             try roomDocRef.setData(from: roomDto)
                             listenToRoom(roomId: roomId)
                         } else {
                             // Room does not exist, create a new room document
                             let roomNickname = RoomDto.generateRoomNickName(username1: newUserRecord.username, username2: friendUserDto.username)
                             
                             let roomDto = RoomDto(id: roomId, userId1: newUserRecord.id, userId2: friendId, lastInteraction: currentTimestamp, nickname: roomNickname)
                             
                             try roomDocRef.setData(from: roomDto)
                             
                             // new room is added, start listening to this room
                             NSLog("LOG: new room is added, start listening to this room")
                             listenToRoom(roomId: roomId)
                         }
                         
                         // Part3
                         // Adding friendRecord
                         let friendRecord = try await self.convertUserDtoToFriendRecord(userDto: friendUserDto)
                         if self.selectedFriend == nil {
                             // set selected friend if this is the first friend that is added
                             self.selectedFriend = friendRecord
                         }
                         
                         if !self.detailedFriends.contains(friendRecord) {
                             DispatchQueue.main.async {
                                 self.detailedFriends.append(friendRecord)
                             }
                             createFriendInDatabase(friend: friendRecord)
                         } else {
//                             NSLog("LOG: friend is already added-FriendRecord")
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

extension RepositoryManager {
    func createUserWhenSignUp(newUserRecord: UserRecord) async {
        DispatchQueue.main.async {
            self.userRecord = newUserRecord
        }

        createUserInDatabase(user: newUserRecord)
        
        do {
            let profileImagePath = try await saveProfileImageInFirebase(id: newUserRecord.id, profileImageData: newUserRecord.profileImageData!)
            let newUserDto = UserDto(id: newUserRecord.id, email: newUserRecord.email, username: newUserRecord.username, pin: newUserRecord.pin, profileImagePath: profileImagePath, deviceToken: newUserRecord.deviceToken)
            createUserInFirebase(userDto: newUserDto)
        } catch {
            NSLog("LOG: Failed to save user when sign up: \(error.localizedDescription)")
        }
    }
}

// MARK: Local Database: User CRUD
extension RepositoryManager {
    func createUserInDatabase(user: UserRecord) {
        do {
            _ = try dbQueue.write { db in
                try user.save(db)
            }
            //            NSLog("LOG: Successfully added new user record")
        } catch {
            print("Failed to save user: \(error)")
        }
    }
    
    func readUserFromDatabase(id: String) -> UserRecord? {
        do {
            let userRecord = try dbQueue.read { db in
                try UserRecord.fetchOne(db, key: id)
            }
            return userRecord
        } catch {
            NSLog("LOG: Failed to read user from database: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func readUserFromDatabase(email: String) -> UserRecord? {
        do {
            let userRecord = try dbQueue.read { db in
                try UserRecord
                    .filter(UserRecord.Columns.email == email)
                    .fetchOne(db)
            }
            return userRecord
        } catch {
            NSLog("LOG: Failed to read user from database: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func eraseAllUsers() {
        do {
            _ = try dbQueue.write { db in
                try UserRecord.deleteAll(db)
            }
            NSLog("LOG: Successfully erased all user records")
        } catch {
            NSLog("LOG: Failed to erase user records: \(error.localizedDescription)")
        }
    }
}

// MARK: Local Database: Friend CRUD
extension RepositoryManager {
    func createFriendInDatabase(friend: FriendRecord) {
        do {
            _ = try dbQueue.write { db in
                try friend.save(db)
            }
        } catch {
            NSLog("LOG: Failed to save friend: \(error.localizedDescription)")
        }
    }
    
    func fetchFriendsByUserIdFromDatabase(userId: String) -> [FriendRecord] {
        do {
            let friends = try dbQueue.read { db in
                try FriendRecord.filter(Column("userId") == userId).fetchAll(db)
            }
            return friends
        } catch {
            return []
        }
    }
    
    func eraseAllFriends() {
        do {
            _ = try dbQueue.write { db in
                try FriendRecord.deleteAll(db)
            }
            NSLog("LOG: Successfully erased all friend records")
        } catch {
            NSLog("LOG: Failed to erase friend records: \(error.localizedDescription)")
        }
    }
}


// MARK: Firebase: Firestore UserDto
extension RepositoryManager {
    func createUserInFirebase(userDto: UserDto) {
        do {
            try usersCollection.document(userDto.id!).setData(from: userDto) { error in
                if let error = error {
                    NSLog("LOG: Error adding user to Firestore: \(error)")
                } else {
                    NSLog("LOG: User successfully added to Firestore")
                }
            }
        } catch let error {
            NSLog("LOG: Error encoding user: \(error)")
        }
    }
    
    func fetchUserFromFirebase(userId: String) async throws -> UserDto {
        try await withCheckedThrowingContinuation { continuation in
            usersCollection.document(userId).getDocument { document, error in
                if let error = error {
                    NSLog("LOG: failed to fetch user dto from firestore: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let document = document, document.exists {
                    do {
                        let userDto = try document.data(as: UserDto.self)
                        continuation.resume(returning: userDto)
                    } catch {
                        NSLog("LOG: failed to convert firestore document to UserDto: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else {
                    NSLog("LOG: failed to fetch user dto from firestore")
                    continuation.resume(throwing: NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document does not exist."]))
                }
            }
        }
    }
    
    func getFriendByPinFromFirebase(friendPin: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            usersCollection.whereField("pin", isEqualTo: friendPin).getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                
                guard let documents = snapshot?.documents, let document = documents.first else {
                    let error = NSError(domain: "getFriendIdByPinError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No such friend with pin: \(friendPin)"])
                    continuation.resume(throwing: error)
                    return
                }
                
                let friendId = document.documentID
                continuation.resume(returning: friendId)
            }
        }
    }

    
    func addFriendIdInFirebase(friendId: String) {
        guard let currentUserId = auth.currentUser?.uid else {
            NSLog("LOG: currentUserId is not set when adding friend id")
            return
        }
        
        let currentUserRef = usersCollection.document(currentUserId)
        currentUserRef.updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ]) { error in
            if let error = error {
                NSLog("LOG: Failed to add friend to firestore: \(error.localizedDescription)")
            }
        }
    }
    
    func updateDeviceTokenInFirebase(userId: String, newDeviceToken: String) {
            usersCollection.document(userId).updateData([
                "deviceToken": newDeviceToken
            ]) { error in
                if let error = error {
                    NSLog("LOG: Error updating device token in Firestore: \(error.localizedDescription)")
                } else {
                    NSLog("LOG: Device token successfully updated in Firestore")
                }
            }
        }
    
    func updateCallStatusInFirebase(friendUid: String, hasIncomingCallRequest: Bool, isBusy: Bool) {
        guard let userId = currentUser?.uid else {
            NSLog("LOG: currentUser is not set when connecting to LiveKit Room")
            return
        }

        guard let roomName = userRecord?.roomName else {
            NSLog("LOG: userRecord is not set when connecting to LiveKit Room")
            return
        }

        let userRef = usersCollection.document(userId)
        let friendRef = usersCollection.document(friendUid)

        let batch = db.batch()
        batch.updateData(["roomName": roomName, "isBusy": isBusy], forDocument: userRef)
        batch.updateData(["hasIncomingCallRequest": hasIncomingCallRequest, "roomName": roomName, "isBusy": isBusy], forDocument: friendRef)
        
        batch.commit { error in
            if let error = error {
                NSLog("Error updating call request: \(error.localizedDescription)")
            } else {
                NSLog("Successfully updated call request and room name for both user and friend.")
            }
        }
    }

}


// MARK: Firebase: Storage
extension RepositoryManager {
    func saveProfileImageInFirebase(id: String, profileImageData: Data) async throws -> String {
        let storageRef = storage.reference().child("profile_images").child("\(id).jpg")
        
        // Upload the image data
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storageRef.putData(profileImageData, metadata: nil) { metadata, error in
                if let error = error {
                    NSLog("LOG: Failed to Store Profile Image to Firebase Storage: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
        // Get the download URL
        let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            storageRef.downloadURL { url, error in
                if let error = error {
                    NSLog("LOG: Failed to Get Profile Image Url from Firebase Storage: \(error)")
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url.absoluteString)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve download URL."]))
                }
            }
        }
        
        return downloadURL
    }
}

// MARK: Fetch User
extension RepositoryManager {
    func fetchUser(id: String) async throws {
        var newUserRecord: UserRecord?
        var needToUpdateLocalUserRecord = false
        
        NSLog("LOG: Fetching user from local database")
        newUserRecord = fetchUserFromLocal(id: id)
        if newUserRecord == nil {
            needToUpdateLocalUserRecord = true
            NSLog("LOG: Local database doesn't have user record")
            NSLog("LOG: Fetching user from remote firestore")
            newUserRecord = try await fetchUserFromRemote(id: id)
        }
        
        if let newUserRecord = newUserRecord {
            DispatchQueue.main.async {
                self.userRecord = newUserRecord
            }
            if needToUpdateLocalUserRecord {
                createUserInDatabase(user: newUserRecord)
                needToUpdateLocalUserRecord = false
            }
            
            NSLog("LOG: Fetching detailedFriends from local database")
            let newDetailedFriends = fetchFriendsByUserIdFromDatabase(userId: newUserRecord.id)
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
    
    private func fetchUserFromLocal(id: String) -> UserRecord? {
        let newUserRecord = readUserFromDatabase(id: id)
        return newUserRecord
    }
    
    private func fetchUserFromRemote(id: String) async throws -> UserRecord {
        do {
            let newUserDto = try await fetchUserFromFirebase(userId: id)
            let newUserRecord = try await convertUserDtoToUserRecord(userDto: newUserDto)
            return newUserRecord
        } catch {
            NSLog("LOG: Error fetching user from Firestore: \(error.localizedDescription)")
            do {
                try self.auth.signOut()
            } catch {
              NSLog("LOG: Failed to sign out in fetchUserFromRemote")
            }
            throw NSError(domain: "fetchUserError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user from remote firestore."])
        }
    }
    
    
    private func fetchFriendAndUpdateLocal(friendId: String) {
        Task {
            do {
                let friendUserDto = try await fetchUserFromFirebase(userId: friendId)
                let friendRecord = try await convertUserDtoToFriendRecord(userDto: friendUserDto)
                if !self.detailedFriends.contains(friendRecord) {
                    DispatchQueue.main.async {
                        self.detailedFriends.append(friendRecord)
                    }
                    self.createFriendInDatabase(friend: friendRecord)
                }
            } catch {
                NSLog("LOG: Error while fetching friend from firestore: \(error.localizedDescription)")
            }
        }
    }
    
    private func convertUserDtoToUserRecord(userDto: UserDto) async throws -> UserRecord {
        guard let profileImagePath = userDto.profileImagePath else {
            throw NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile image path is not set."])
        }
        
        let storageRef = storage.reference(forURL: profileImagePath)
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
        
        let storageRef = storage.reference(forURL: profileImagePath)
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
        
        let friendId = userDto.id!
        let roomId = RoomDto.generateRoomId(userId1: userId, userId2: friendId)
        let roomDto = try await fetchRoomFromFirebase(roomId: roomId)
        
        let friendRecord = FriendRecord(
            id: userDto.id ?? UUID().uuidString,
            email: userDto.email,
            username: userDto.username,
            pin: userDto.pin,
            profileImageData: imageData,
            deviceToken: userDto.deviceToken,
            userId: userId,
            isBusy: userDto.isBusy,
            lastInteraction: roomDto?.lastInteraction.dateValue()
        )
        
        return friendRecord
    }
}

// MARK: update timestamp on long press
extension RepositoryManager {
    func updateTimestampWhenLongPress(friendId: String) {
        // Get current timestamp
        let currentTimestamp = Date()
        
        // Get current user ID from 'userRecord'
        guard let currentUserId = userRecord?.id else {
            NSLog("LOG: currentUserId is not available when updating timestamp")
            return
        }
        
        guard let userRecord = userRecord else {
            NSLog("LOG: userRecord is not available when updating timestamp")
            return
        }
        
        // Just need to update timestamp value in firebase
        // Memory and Local db update will be handled by room listener
        
        // Get room id
        let roomId = RoomDto.generateRoomId(userId1: currentUserId, userId2: friendId)
        
        // Update 'lastInteraction' value in room document
        updateTimestampInFirebase(roomId: roomId, currentTimestamp: currentTimestamp)
    }
}

// MARK: Firebase: Firestore RoomDto
extension RepositoryManager {
    func fetchRoomFromFirebase(roomId: String) async throws -> RoomDto? {
        try await withCheckedThrowingContinuation { continuation in
            roomsCollection.document(roomId).getDocument { document, error in
                if let error = error {
                    NSLog("LOG: failed to fetch room dto from firestore: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                } else if let document = document, document.exists {
                    do {
                        let roomDto = try document.data(as: RoomDto.self)
                        continuation.resume(returning: roomDto)
                    } catch {
                        NSLog("LOG: Failed to convert firestore document to roomDto: \(error.localizedDescription)")
                        continuation.resume(returning: nil)
                    }
                } else {
                    NSLog("LOG: Failed to fetch room dto from firestore")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func updateTimestampInFirebase(roomId: String, currentTimestamp: Date) {
        // Get a reference to the room document
        let roomDocument = roomsCollection.document(roomId)
        
        // Update the 'lastInteraction' field with the current timestamp
        roomDocument.updateData([
            "lastInteraction": currentTimestamp
        ]) { error in
            if let error = error {
                NSLog("LOG: Failed to update timestamp in Firebase: \(error.localizedDescription)")
            } else {
                NSLog("LOG: Successfully updated timestamp in Firebase for roomId: \(roomId)")
            }
        }
    }
}

extension RepositoryManager {
    func removeAllListeners() {
        // Cancel and remove all room listeners
        for listener in roomsListeners {
            listener.remove()
        }
        roomsListeners.removeAll()
        
        // Cancel and remove all friend listeners
        for listener in friendsListeners {
            listener.remove()
        }
        friendsListeners.removeAll()
        
        // Cancel and remove the user listener if it exists
        userListener?.remove()
        userListener = nil
        
        NSLog("LOG: Successfully removed all listeners")
    }
}

// MARK: Update 'UserDto.isActive' value
extension RepositoryManager {
    // TODO: add two function that increment/decrement isActive value by 1
}

enum UserState {
    case isSpeaking
    case isListening
    case idle
}
