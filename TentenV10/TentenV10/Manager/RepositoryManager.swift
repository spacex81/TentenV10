import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GRDB

class RepositoryManager: ObservableObject {
    static let shared = RepositoryManager()
    
    private let liveKitManager = LiveKitManager.shared
    weak var collectionViewController: CustomCollectionViewController?
    
    let deleteUserByUIDUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/deleteUserByUID"
    
    // Local Database
//    private var dbQueue: DatabaseQueue!
    private var dbPool: DatabasePool!
    
    
    // Firebase
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    let usersCollection: CollectionReference
    let roomsCollection: CollectionReference
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var roomsListeners: [String: ListenerRegistration] = [:]
    private var friendsListeners: [String: ListenerRegistration] = [:] {
        didSet {
//            NSLog("LOG: friendsListeners")
//            print(friendsListeners)
        }
    }
    private var userListener: ListenerRegistration? {
        didSet {
//            NSLog("LOG: RepositoryManager-userListener: \(String(describing: userListener))")
        }
    }
    
    private var previousState: UserState = .idle
    
    @Published var currentState: UserState = .idle {
        didSet {
            // Check if the state has changed from .isListening to .idle
            if previousState == .isListening && currentState == .idle {
                // Reload data only when transitioning from .isListening to .idle
//                NSLog("LOG: reloadData when connection state changed from isListening to idle")
                collectionViewController?.reloadData()
            } else if currentState == .isListening {
                // When transitioning to .isListening, update the collection view
//                NSLog("LOG: reloadData when connection state is set to isListening")
                collectionViewController?.reloadData()
            }
            
            // Update the previousState to the current state
            previousState = currentState
        }
    }
    
    @Published var userRecord: UserRecord? {
        didSet {
//            NSLog("LOG: RepositoryManager-userRecord.status: \(userRecord?.status ?? "nil")")
//            print(userRecord ?? "userRecord is nil")
            
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
                
                syncFriendInfo()
                syncDetailedFriends(friendIds: userRecord.friends)
                updateStatusWhenAppLaunch()
                
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
    
    func updateStatusWhenAppLaunch() {
        // Check if app is in the foreground
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background {
                // Check if userRecord.status is not 'foreground'
                if self.userRecord?.status != "foreground" {
    //                NSLog("LOG: User status is not 'foreground', updating status")
                    // Update the status to 'foreground'
                    self.updateStatus(to: "foreground")
                }
            }
        }
    }
    
    func updateStatus(to status: String) {
        guard var newUserRecord = userRecord else {
            NSLog("LOG: No user record found to update status")
            return
        }

        let userId = newUserRecord.id
        let currentTime = Date()
        
        newUserRecord.status = status
        
        // Update memory
        DispatchQueue.main.async {
            self.userRecord = newUserRecord
        }
        
        // Update local db
        createUserInDatabase(user: newUserRecord)
        
        // Update remote Firebase
        updateUserField(userId: userId, fieldsToUpdate: [
            "status": status,
            "lastActive": currentTime
        ])
        
//        NSLog("LOG: User status updated to \(status)")
    }
    
    func syncFriendInfo() {
        Task {
//            NSLog("LOG: SplashView-syncFriendInfo")
            // Ensure we have the user record and the list of friends
            guard var friendIds = userRecord?.friends else {
                NSLog("LOG: No friends to sync.")
                return
            }

            // Create a list to keep track of friends to remove
            var friendsToRemove: [String] = []

            // Iterate over each friend ID
            for friendId in friendIds {
                do {
                    // MARK: Check if the friend has deleted the current user
                    let isDeleted = try await checkIfFriendDeletedYou(friendId: friendId, currentUserId: userRecord?.id ?? "")
                    if isDeleted {
                        // If the friend has deleted the user, add their ID to the list for removal
                        friendsToRemove.append(friendId)
                    }
                    
                    // MARK: Check if the friend updated their profile image
                } catch {
                    NSLog("LOG: Error checking if friend deleted you for friendId \(friendId): \(error.localizedDescription)")
                }
            }

            // Remove friends who have deleted the user from the user record
            if !friendsToRemove.isEmpty {
                // Update the userRecord with filtered friendIds
                friendIds.removeAll { friendsToRemove.contains($0) }
                userRecord?.friends = friendIds
                
                // Update the database or Firestore if needed
                // Example: repoManager.updateUserRecordInDatabase(repoManager.userRecord)
                NSLog("LOG: Updated userRecord friends after sync: \(friendIds)")
            }
        }
    }

    
    func syncDetailedFriends(friendIds: [String]) {
        // Find friends in 'detailedFriends' that are not in 'friendIds'
        let friendsToRemove = detailedFriends.filter { !friendIds.contains($0.id) }
        
        // Remove each of these friends from 'detailedFriends' and the local database
        for friend in friendsToRemove {
            if let index = detailedFriends.firstIndex(where: { $0.id == friend.id }) {
                // Remove from the detailedFriends array
                detailedFriends.remove(at: index)
                
                // Remove from the local database
                eraseFriendFromDatabase(friendId: friend.id)
                
                NSLog("LOG: Removed friend with ID \(friend.id) from detailedFriends and local database")
            }
        }
    }
    
    func syncIsBusy() {
//        NSLog("LOG: RepositoryManager-syncIsBusy")
        
        if var userRecord = userRecord {
//            NSLog("LOG: isBusy: \(userRecord.isBusy)")
//            NSLog("LOG: currentState: \(currentState)")
            
            Task {
                do {
                    let userDto = try await self.fetchUserFromFirebase(userId: userRecord.id)
                    if userDto.isBusy && currentState == .idle {
                        userRecord.isBusy = false
                        let newUserRecord = userRecord
                        
                        DispatchQueue.main.async {
                            self.userRecord = newUserRecord
                        }
                        
                        createUserInDatabase(user: newUserRecord)
                        updateUserField(userId: userRecord.id, fieldsToUpdate: ["isBusy": false])
                    }
                } catch {
                    NSLog("LOG: RepositoryManager-syncIsBusy: Failed to fetch userDto from firebase")
                }
            }
        } else {
            NSLog("LOG: userRecord is nil")
        }
    }
    
    @Published var selectedFriend: FriendRecord? {
        didSet {
//            NSLog("LOG: RepositoryManager-selectedFriend")
            Task {
//                NSLog("LOG: reloadData() is run when selectedFriend has changed")
                await self.collectionViewController?.reloadData()
            }
            
//            if let selectedFriend = selectedFriend {
//                print(selectedFriend)
//            } else {
//                print("selectedFriend is nil")
//            }
            

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
//            NSLog("LOG: repoManager-detailedFriends")
//            print(detailedFriends)
            
//            NSLog("LOG: repoManager-detailedFriends from local db")
//            let friendsFromDb = fetchAllFriendsFromDatabase()
//            print(friendsFromDb)
            
            if detailedFriends.count > 0 && selectedFriend == nil {
                selectedFriend = detailedFriends[0]
            }
            
            Task {
//                NSLog("LOG: reloadData() is run when detailedFriends has changed")
                await self.collectionViewController?.reloadData()
            }
        }
    }
    
    @Published var needUserFetch = true
    
    @Published var currentUser: User?
    
    // MARK: Listen to room
    var currentSpeakerId: String? {
        didSet {
//            NSLog("LOG: currentSpeakerId is \(currentSpeakerId ?? "nil")")
        }
    }
    //

    init() {
        usersCollection = db.collection("users")
        roomsCollection = db.collection("rooms")
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
        setupDatabase()
        startListeningToAuthChanges()
        
        liveKitManager.repoManager = self
    }
    
    private var printTimer: Timer?
    
    deinit {
        stopListeningToAuthChanges()
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
    }
    
    private func updateDeviceToken(oldUserRecord: UserRecord, newDeviceToken: String) {
//        NSLog("LOG: updateDeviceToken")
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
//                    NSLog("self.currentUser is set")
                } else {
                    self.currentUser = nil
//                    NSLog("self.currentUser is nil")
                }
            }
        }
    }
    
    func stopListeningToAuthChanges() {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
}

extension RepositoryManager {
    private func setupDatabase() {
        do {
            guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.GHJU9V8GHS.tech.komaki.TentenV10") else {
                NSLog("LOG: Could not find app group container.")
                return
            }
            
            let databaseURL = appGroupURL.appendingPathComponent("db.sqlite")
            dbPool = try DatabasePool(path: databaseURL.path)
            
            var migrator = DatabaseMigrator()

            // v1: Initial database setup
            migrator.registerMigration("v1") { db in
                try db.create(table: "users") { t in
                    t.column("id", .text).primaryKey()
                    t.column("email", .text).notNull()
                    t.column("username", .text).notNull()
                    t.column("password", .text).notNull()
                    t.column("pin", .text).notNull()
                    t.column("hasIncomingCallRequest", .boolean).notNull().defaults(to: false)
                    t.column("profileImageData", .blob)
                    t.column("deviceToken", .text)
                    t.column("friends", .text)
                    t.column("receivedInvitations", .text)
                    t.column("sentInvitations", .text)
                    t.column("roomName", .text).notNull().defaults(to: "testRoom")
                    t.column("isBusy", .boolean).notNull().defaults(to: false)
                    t.column("socialLoginId", .text).notNull()
                    t.column("socialLoginType", .text).notNull()
                    t.column("imageOffset", .double).notNull().defaults(to: 0.0)
                    
                    // Add new fields
                    t.column("status", .text).notNull().defaults(to: "background")
                    t.column("lastActive", .datetime)
                }
                
                // Create the friends table with 'lastInteraction' column and new 'isAccepted' column
                try db.create(table: "friends") { t in
                    t.column("id", .text).primaryKey()
                    t.column("email", .text).notNull()
                    t.column("username", .text).notNull()
                    t.column("pin", .text).notNull()
                    t.column("profileImageData", .blob)
                    t.column("deviceToken", .text)
                    t.column("userId", .text).notNull().references("users", onDelete: .cascade)
                    t.column("isBusy", .boolean).notNull().defaults(to: false)
                    t.column("lastInteraction", .datetime)
                    t.column("isAccepted", .boolean).notNull().defaults(to: false)
                }
            }

            // v2: Add 'status' column to 'friends' table
            migrator.registerMigration("v2_add_status_to_friends") { db in
                try db.alter(table: "friends") { t in
                    t.add(column: "status", .text).notNull().defaults(to: "background")
                }
            }

            // Migrate the database to the latest version
            try migrator.migrate(dbPool)
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
        
        roomsListeners.forEach { $0.value.remove() }
        roomsListeners.removeAll()
        
        friends.forEach { friendId in
            let roomId = RoomDto.generateRoomId(userId1: userRecord.id, userId2: friendId)
            listenToRoom(roomId: roomId)
        }
    }
    
    func listenToFriends(userRecord: UserRecord) {
        let friends = userRecord.friends

        // Clear existing listeners before setting up new ones
        friendsListeners.forEach { $0.value.remove() }
        friendsListeners.removeAll()

        // Listen to each friend
        friends.forEach { listenToFriend(friendId: $0) }
    }
    
    func listenToUser(userRecord: UserRecord) {
        NSLog("LOG: RepositoryManager-listenToUser")
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
                         
                         let updatedUserRecord = try await self.convertUserDtoToUserRecord(userDto: userDto)
                         
                         NSLog("LOG: listenToUser-updatedUserRecord")
                         print(updatedUserRecord)
                         
                         let invitations = updatedUserRecord.receivedInvitations
                         self.handleReceivedInvitations(friendIds: invitations)
                         
                         self.handleUpdateFriends(oldUserRecord: self.userRecord, newUserRecord: updatedUserRecord)
                         
                         if self.userRecord != updatedUserRecord {
                             DispatchQueue.main.async {
//                                 NSLog("LOG: UserRecord is set")
                                 self.userRecord = updatedUserRecord
                             }
                             self.createUserInDatabase(user: updatedUserRecord)
                         }
                     } catch {
                         print("Error converting UserDto to UserRecord: \(error.localizedDescription)")
                     }
                 }
             } else {
                 print("Document does not exist when trying to listen to user")
                 AuthManager.shared.isOnboardingComplete = false
                 AuthManager.shared.signOut()
             }
         }
     }
    
    private func handleReceivedInvitations(friendIds: [String]) {
//        NSLog("LOG: handleReceivedInvitations")
        let contentViewModel = ContentViewModel.shared

        ReceivedInvitationsTaskQueue.shared.addTask {
//            NSLog("LOG: Running handleReceivedInvitations task")

            if friendIds.count > 0 {
                DispatchQueue.main.async {
                    Task {
                        var invitations: [Invitation] = []
                        for id in friendIds {
                            do {
                                let invitation = try await self.processFriendInvitation(friendId: id)
                                invitations.append(invitation)
                            } catch {
                                NSLog("LOG: Error processing friend invitation for id \(id): \(error.localizedDescription)")
                            }
                        }
                        
                        NSLog("LOG: Updating receivedInvitations in listenToUser")
                        print(invitations)
                        contentViewModel.receivedInvitations = invitations
                        contentViewModel.previousInvitationCount = friendIds.count
                        contentViewModel.showPopup = true

                        // Mark the task as completed
                        ReceivedInvitationsTaskQueue.shared.taskCompleted()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    contentViewModel.showPopup = false
                    // Mark the task as completed
                    ReceivedInvitationsTaskQueue.shared.taskCompleted()
                }
            }
        }
    }
    
    private func processFriendInvitation(friendId: String) async throws -> Invitation {
        NSLog("LOG: processFriendInvitation")
        // MARK: In order to persist invitation cards eventhough user suspends our app, we need to store the FriendRecord that corresponds to friendId
        
        // Check if the local database already has a FriendRecord corresponding to the friendId
        let localFriendRecords = fetchFriendsByUserIdFromDatabase(userId: friendId)
        NSLog("LOG: fetchFriendsByUserIdFromDatabase finished")
        if let localFriend = localFriendRecords.first {
            // If a FriendRecord exists locally, use it to create and return an Invitation
            return Invitation(id: localFriend.id, username: localFriend.username, profileImageData: localFriend.profileImageData ?? Data())
        } else {
            // If not, fetch the FriendRecord from Firebase
            do {
                let fetchedFriend = try await fetchFriendFromFirebase(friendId: friendId)
                // Store the fetched FriendRecord in the local database
                createFriendInDatabase(friend: fetchedFriend)
                // Use the fetched FriendRecord to create and return an Invitation
                return Invitation(id: fetchedFriend.id, username: fetchedFriend.username, profileImageData: fetchedFriend.profileImageData ?? Data())
            } catch {
                NSLog("LOG: Error fetching friend from Firebase: \(error.localizedDescription)")
                throw error
            }
        }
    }

    
    private func handleSentInvitations() {
        NSLog("LOG: handleSentInvitations")
    }
    
    private func handleUpdateFriends(oldUserRecord: UserRecord?, newUserRecord: UserRecord) {
        FriendsUpdateTaskQueue.shared.addTask {
//            NSLog("LOG: handleUpdateFriends")
            
            // Compare old friends list with the new one
            let oldFriends = Set(oldUserRecord?.friends ?? [])
            let newFriends = Set(newUserRecord.friends)
//            NSLog("LOG: oldFriends")
//            print(oldFriends)
//            NSLog("LOG: newFriends")
//            print(newFriends)
            
            // Find friends that were removed and added
            let removedFriends = oldFriends.subtracting(newFriends)
            let addedFriends = newFriends.subtracting(oldFriends)
            
            // Handle removed friends
            removedFriends.forEach { friendId in
                self.deleteFriend(friendId: friendId)
            }
            
            // Handle added friends asynchronously
            Task {
                for friendId in addedFriends {
                    await self.addFriend(friendId: friendId)
                }
                
                // Mark the task as completed once all operations are done
                FriendsUpdateTaskQueue.shared.taskCompleted()
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
                        NSLog("LOG: RepositoryManager-listenToFriend-newFriendRecord")
                        print(newFriendRecord)
                        
                        DispatchQueue.main.async {
                            if let index = self.detailedFriends.firstIndex(where: { $0.id == newFriendRecord.id }) {
                                self.detailedFriends[index] = newFriendRecord
                                
                                // MARK: When one of the friend reinstall the app and changes the device token value, we need to update that
                                if self.selectedFriend?.id == newFriendRecord.id {
                                    self.selectedFriend = newFriendRecord
                                }
                            } else {
//                                NSLog("LOG: New friend is added in friend listener")
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

        friendsListeners[friendId] = friendListener
    }
}

// MARK: Listen to room
extension RepositoryManager {
    func listenToRoom(roomId: String) {
        let roomListener = roomsCollection.document(roomId).addSnapshotListener { [weak self] document, error in
            guard let self = self else { return }
            guard let userRecord = self.userRecord else {
                NSLog("LOG: userRecord is not set when trying to use it in room listener")
                return
            }
            let currentUserId = userRecord.id

            if let error = error {
                NSLog("LOG: Error listening to room: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                Task {
                    do {
                        NSLog("LOG: listenToRoom-Update room document from room listener")
                        let roomDto = try self.convertRoomDocumentToRoomDto(document: document)
                        NSLog("LOG: Updated RoomDto")
                        print(roomDto)
                        
                        self.updateCurrentSpeaker(roomDto: roomDto, currentUserId: currentUserId)
                        await self.updateLastInteraction(roomDto: roomDto, currentUserId: currentUserId)
                    } catch {
                        NSLog("LOG: Error decoding roomDto: \(error.localizedDescription)")
                    }
                }
            }
        }
        roomsListeners[roomId] = roomListener
    }
    
    func updateCurrentSpeaker(roomDto: RoomDto, currentUserId: String) {
//        NSLog("LOG: updateCurrentSpeaker")

        UpdateCurrentSpeakerQueue.shared.addTask {
            guard let friendId = roomDto.getFriendId(currentUserId: currentUserId) else {
                NSLog("LOG: RepositoryManager-updateCurrentSpeaker: friendId is nil")
                UpdateCurrentSpeakerQueue.shared.taskCompleted()
                return
            }

//            NSLog("LOG: friendId: \(friendId)")
//            NSLog("LOG: isActive: \(roomDto.isActive)")
//            NSLog("LOG: currentSpeakerId: \(self.currentSpeakerId ?? "nil")")
            
            if roomDto.isActive == 1 && self.currentSpeakerId == nil {
                self.currentSpeakerId = friendId
            } else if roomDto.isActive == 0 && self.currentSpeakerId == friendId {
//                self.currentSpeakerId = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.currentSpeakerId = nil
                }
            }

            // Mark the task as completed
            UpdateCurrentSpeakerQueue.shared.taskCompleted()
        }
    }
    
    func updateLastInteraction(roomDto: RoomDto, currentUserId: String) async {
        let friendId = roomDto.getFriendId(currentUserId: currentUserId)
        
        // Find the friend in detailedFriends
        if let index = self.detailedFriends.firstIndex(where: { $0.id == friendId }) {
            let currentLastInteraction = self.detailedFriends[index].lastInteraction
            let newLastInteraction = roomDto.lastInteraction.dateValue()
            
            // Update only if the lastInteraction value has changed
            if currentLastInteraction != newLastInteraction {
                // Update timestamp value in detailedFriends
                self.detailedFriends[index].lastInteraction = newLastInteraction
                
//                                NSLog("LOG: Sort new detailedFriends")
                // Sort new detailedFriends
                self.sortDetailedFriends()
//                                NSLog("LOG: reloadData when detailedFriends is sorted")
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
    }
}

// MARK: Invite friend
extension RepositoryManager {
    func inviteFriend(friendPin: String) async {
        guard let userRecord = userRecord else {
            NSLog("LOG: userRecord is nil when adding friend")
            return
        }
        
        if friendPin == userRecord.pin {
            NSLog("LOG: This is your pin. Please enter your friend's pin")
            return
        }
        
        do {
            if !friendPin.isEmpty {
                let friendId = try await getFriendIdByPinFromFirebase(friendPin: friendPin)
                // get current user id
                let currentUserId = userRecord.id
                // add 'friendId' to current user's 'sentInvitations' in firestore
                updateInvitationListInFirebase(documentId: currentUserId, friendId: friendId, action: .add, listType: .sent)
                // add current user id to friend's 'receivedInvitations' in firestore
                updateInvitationListInFirebase(documentId: friendId, friendId: currentUserId, action: .add, listType: .received)
            }
        } catch {
            NSLog("LOG: Error inviting friend by pin: \(error.localizedDescription)")
        }
    }
}

// MARK: Adding/Deleting friend
extension RepositoryManager {
    func addFriend(friendPin: String) async {
        guard var newUserRecord = userRecord else {
            NSLog("LOG: userRecord is nil when adding friend")
            return
        }
        
        if friendPin == newUserRecord.pin {
            NSLog("LOG: This is your pin. Please enter your friend's pin")
            return
        }
        
        do {
            if !friendPin.isEmpty {
                let friendId = try await getFriendIdByPinFromFirebase(friendPin: friendPin)
                
//                if !newUserRecord.friends.contains(friendId) {
                if !newUserRecord.friends.contains(friendId) || !friendExistInDatabase(userId: friendId) {
                    
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
                        let roomDto = try self.convertRoomDocumentToRoomDto(document: roomDoc)
//                        NSLog("LOG: Room document converted successfully to RoomDto in addFriend")
//                        print(roomDto)

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
                        // NSLog("LOG: friend is already added-FriendRecord")
                    }
                    
                    await collectionViewController?.reloadData()
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
    
    func addFriend(friendId: String) async {
        NSLog("LOG: RepositoryManager-addFriend()")
        
        guard var newUserRecord = userRecord else {
            NSLog("LOG: userRecord is nil when adding friend")
            return
        }
        
        do {
//            if !newUserRecord.friends.contains(friendId) {
            if !newUserRecord.friends.contains(friendId) || !friendExistInDatabase(userId: friendId) {
                let currentTimestamp = Date()
                // fetch detailed friend
                let friendUserDto = try await fetchUserFromFirebase(userId: friendId)
                
                newUserRecord.friends.append(friendId)
                
                // Part1
                // Storing user information
                DispatchQueue.main.async {
//                    NSLog("LOG: Updating adding friendId to userRecord.friends")
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
                    // NSLog("LOG: friend is already added-FriendRecord")
                }
            } else {
//                NSLog("LOG: friend is already added-FriendID")
//                NSLog("LOG: newUserRecord")
//                print(newUserRecord)
            }

        } catch {
            NSLog("LOG: Error adding friend by pin: \(error.localizedDescription)")
        }
    }

    
    func deleteFriend(friendId: String) {
        NSLog("LOG: RepositoryManager-deleteFriend")
        
        guard let currentUserId = auth.currentUser?.uid else {
            NSLog("LOG: currentUserId is not set when removing friend id")
            return
        }
        
        // 1) Delete friend from memory
        if let index = self.detailedFriends.firstIndex(where: { $0.id == friendId }) {
            self.detailedFriends.remove(at: index)
//            NSLog("LOG: Successfully removed friend from memory")
        } else {
            NSLog("LOG: Failed to find friend in memory")
            return
        }
        
        // 2) Delete friend from local database
        eraseFriendFromDatabase(friendId: friendId)
//        NSLog("LOG: Successfully removed friend from local database")
//        let currentFriends = fetchAllFriendsFromDatabase()
//        NSLog("LOG: currentFriends")
//        print(currentFriends)
        
        // 3) Remove friend id in UserRecord.friends
        updateCurrentUserFriends(friendId: friendId)
        
        // 4) Delete friend from current user's Firebase document
        updateFriendListInFirebase(documentId: currentUserId, friendId: friendId, action: .remove)
        updateFriendListInFirebase(documentId: friendId, friendId: currentUserId, action: .remove)
        
        // 5) Remove friend listener using friendId
        if let listener = friendsListeners[friendId] {
            listener.remove()
            friendsListeners.removeValue(forKey: friendId)
//            NSLog("LOG: Successfully removed listener for friendId: \(friendId)")
        } else {
            NSLog("LOG: No listener found for friendId: \(friendId)")
        }
        
        let roomId = RoomDto.generateRoomId(userId1: currentUserId, userId2: friendId)
        
        // 6) Remove room from firebase
        removeRoomFromFirebase(roomId: roomId)
        
        // 7) Remove room listener
        if let roomListener = roomsListeners[roomId] {
            roomListener.remove()
            roomsListeners.removeValue(forKey: roomId)
//            NSLog("LOG: Successfully removed room listener for roomId: \(roomId)")
        } else {
            NSLog("LOG: No room listener found for roomId: \(roomId)")
        }
        
        if detailedFriends.count > 0 {
            selectedFriend = detailedFriends[0]
        } else {
            selectedFriend = nil
            DispatchQueue.main.async {
                ContentViewModel.shared.onboardingStep = .addFriend
            }
        }
        
        Task {
            await self.collectionViewController?.reloadData()
        }

//        NSLog("LOG: Successfully removed friend with id: \(friendId) from Firebase")
//        NSLog("LOG: deleteFriend-selectedFriend")
//        print(selectedFriend ?? "selectedFriend is nil")
//        NSLog("LOG: deletedFriend-detailedFriends")
//        print(detailedFriends)
    }
    
    private func updateCurrentUserFriends(friendId: String) {
        NSLog("LOG: updateCurrentUserFriends")
        
        guard let currentUser = readUserFromDatabase(id: auth.currentUser?.uid ?? "") else {
            NSLog("LOG: Failed to retrieve current user from local database")
            return
        }
        
        NSLog("LOG: currentUser")
        print(currentUser)
        
        // Check if friend is in the list
        if let index = currentUser.friends.firstIndex(of: friendId) {
            var updatedUser = currentUser
            
            NSLog("LOG: friendId: \(friendId)")
            NSLog("LOG: index: \(index)")

            NSLog("LOG: updatedUser.friends before remove")
            print(updatedUser.friends)
            updatedUser.friends.remove(at: index) // Remove friend ID from friends list
            
            NSLog("LOG: updatedUser.friends after remove")
            print(updatedUser.friends)
            
            DispatchQueue.main.async {
                self.userRecord = updatedUser
            }

            // Update the user record in the database
            createUserInDatabase(user: updatedUser) // Re-save the updated UserRecord
//            let userFromDb = readUserFromDatabase(id: updatedUser.id)
//            NSLog("LOG: userFromDb")
//            print(userFromDb ?? "userFromDb is nil")
            
//            let userRecordsFromDb = readAllUsersFromDatabase()
//            NSLog("LOG: userRecordsFromDb")
//            print(userRecordsFromDb)
            
//            NSLog("LOG: Successfully removed friend from currentUser.friends and updated in local database")
        } else {
            NSLog("LOG: Friend ID not found in currentUser.friends")
        }
    }
}

extension RepositoryManager {
    func createUserWhenSignUp(newUserRecord: UserRecord) async {
        DispatchQueue.main.async {
            self.userRecord = newUserRecord
        }

        createUserInDatabase(user: newUserRecord)
        
        let newUserDto = UserDto(
            id: newUserRecord.id,
            email: newUserRecord.email,
            username: newUserRecord.username,
            password: newUserRecord.password, // Include password here
            pin: newUserRecord.pin,
            deviceToken: newUserRecord.deviceToken,
            socialLoginId: newUserRecord.socialLoginId,
            socialLoginType: newUserRecord.socialLoginType
        )
    
        createUserInFirebase(userDto: newUserDto)
    }
}

extension RepositoryManager {
    func deleteCurrentUser() async {
        guard let user = userRecord else {
            NSLog("LOG: No user record found to delete")
            return
        }
        let uid = user.id

        // 1. Remove from local database
        deleteUserFromDatabase(user: user)

        // 2. Remove from Firebase Firestore
        deleteUserFromFirebase(user: user)
        
        // 3. Remove current user from each friend's Firebase user document's 'friends' field
        await removeCurrentUserFromFriendsList()
        
        // 4. Also need to add remove rooms
        await removeRoomsForCurrentUser()
        
        // 5. Remove user from Firebase Authentication
        _ = await deleteUserFromFirebaseAuth(uid: uid)

        // 6. Clean up related data
        cleanUpUserData()

        DispatchQueue.main.async {
            // Reset any state in your view models or repository
            HomeViewModel.shared.username = ""
            HomeViewModel.shared.profileImageData = nil
            HomeViewModel.shared.imageOffset = 0.0
            self.userRecord = nil
            self.detailedFriends = []
            self.selectedFriend = nil
            self.removeAllListeners()
            self.eraseAllUsers()
            self.eraseAllFriendsFromDatabase()
        }

        NSLog("LOG: User account and related data deleted successfully")
    }
    
    private func removeCurrentUserFromFriendsList() async {
        guard let currentUserId = userRecord?.id else {
            NSLog("LOG: No current user found to remove from friends list")
            return
        }

        // Iterate over all friends of the current user
        for friendId in userRecord?.friends ?? [] {
            // Use the updateFriendListInFirebase function to remove the current user from each friend's friends list
            updateFriendListInFirebase(documentId: friendId, friendId: currentUserId, action: .remove)
        }

        NSLog("LOG: Successfully removed current user from all friends' lists.")
    }
}


// MARK: Local Database: User CRUD
extension RepositoryManager {
    func createUserInDatabase(user: UserRecord) {
        do {
            _ = try dbPool.write { db in
                try user.save(db)
            }
            //            NSLog("LOG: Successfully added new user record")
        } catch {
            print("Failed to save user: \(error)")
        }
    }
    
    func deleteUserFromDatabase(user: UserRecord) {
        do {
            _ = try dbPool.write { db in
                try user.delete(db)
            }
            NSLog("LOG: User successfully deleted from local database")
        } catch {
            NSLog("LOG: Failed to delete user from local database: \(error)")
        }
    }
    
    func readUserFromDatabase(id: String) -> UserRecord? {
        do {
            let userRecord = try dbPool.read { db in
                try UserRecord.fetchOne(db, key: id)
            }
            return userRecord
        } catch {
            NSLog("LOG: Failed to read user from database: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func readAllUsersFromDatabase() -> [UserRecord] {
        do {
            let userRecords = try dbPool.read { db in
                try UserRecord.fetchAll(db)
            }
            return userRecords
        } catch {
            NSLog("LOG: Failed to read all users from database: \(error.localizedDescription)")
            return []
        }
    }
    
    func readUserFromDatabase(email: String) -> UserRecord? {
        do {
            let userRecord = try dbPool.read { db in
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
            _ = try dbPool.write { db in
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
//        NSLog("LOG: RepositoryManager-createFriendInDatabase: friend")
//        print(friend)
        do {
            _ = try dbPool.write { db in
                try friend.save(db)
            }
        } catch {
            NSLog("LOG: Failed to save friend: \(error.localizedDescription)")
        }
    }
    
    func fetchFriendsByUserIdFromDatabase(userId: String) -> [FriendRecord] {
        do {
            let friends = try dbPool.read { db in
                try FriendRecord.filter(Column("userId") == userId).fetchAll(db)
            }
            return friends
        } catch {
            return []
        }
    }
    
    func friendExistInDatabase(userId: String) -> Bool {
        let friends = fetchFriendsByUserIdFromDatabase(userId: userId)
        if friends.count > 0 {
            return true
        } else {
            return false
        }
    }
    
    func fetchAllFriendsFromDatabase() -> [FriendRecord] {
        do {
            let friends = try dbPool.read { db in
                try FriendRecord.fetchAll(db)
            }
            return friends
        } catch {
            NSLog("LOG: Failed to fetch all friends: \(error.localizedDescription)")
            return []
        }
    }
    
    func eraseFriendFromDatabase(friendId: String) {
        do {
            _ = try dbPool.write { db in
                // Find the friend by friendId and delete it
                try FriendRecord.filter(Column("id") == friendId).deleteAll(db)
            }
//            NSLog("LOG: Successfully erased friend with id: \(friendId)")
        } catch {
            NSLog("LOG: Failed to erase friend with id \(friendId): \(error.localizedDescription)")
        }
    }
    
    func eraseAllFriendsFromDatabase() {
        do {
            _ = try dbPool.write { db in
                try FriendRecord.deleteAll(db)
            }
//            NSLog("LOG: Successfully erased all friend records")
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
    
    func deleteUserFromFirebase(user: UserRecord) {
//        guard let userId = user.id else {
//            NSLog("LOG: User ID not found, cannot delete from Firebase")
//            return
//        }
        let userId = user.id
        
        usersCollection.document(userId).delete { error in
            if let error = error {
                NSLog("LOG: Failed to delete user from Firestore: \(error)")
            } else {
                NSLog("LOG: User successfully deleted from Firestore")
            }
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
    
    func checkIfFriendDeletedYou(friendId: String, currentUserId: String) async throws -> Bool {
        do {
            // Fetch the friend's UserDto from Firestore
            let friendDto = try await fetchUserFromFirebase(userId: friendId)
            
            // Check if the current user's ID is present in the friend's 'friends' field
            if friendDto.friends.contains(currentUserId) {
                // The friend still has the current user in their friends list
                return false
            } else {
                // The friend does not have the current user in their friends list
                return true
            }
        } catch {
            NSLog("LOG: Failed to check if friend deleted you: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchFriendFromFirebase(friendId: String) async throws -> FriendRecord {
        // Fetch the UserDto using the friendId
        let userDto = try await fetchUserFromFirebase(userId: friendId)
        
        // Convert the UserDto to a FriendRecord
        let friendRecord = try await convertUserDtoToFriendRecord(userDto: userDto)
        
        return friendRecord
    }

    
    func fetchUserFromFirebase(field: String, value: String) async throws -> UserDto? {
        try await withCheckedThrowingContinuation { continuation in
            usersCollection.whereField(field, isEqualTo: value).getDocuments { snapshot, error in
                if let error = error {
                    NSLog("LOG: Failed to fetch user dto from Firestore by \(field): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot, let document = snapshot.documents.first {
                    do {
                        let userDto = try document.data(as: UserDto.self)
                        continuation.resume(returning: userDto)
                    } catch {
                        NSLog("LOG: Failed to convert Firestore document to UserDto: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else {
                    // No matching document found
                    NSLog("LOG: No matching user found for \(field) = \(value)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func fetchUserFromFirebase(fields: [String: String]) async throws -> UserDto? {
        try await withCheckedThrowingContinuation { continuation in
            var query: Query = usersCollection

            // Apply whereField for each key-value pair in the fields dictionary
            for (field, value) in fields {
                query = query.whereField(field, isEqualTo: value)
            }

            query.getDocuments { snapshot, error in
                if let error = error {
                    NSLog("LOG: Failed to fetch user from Firestore with fields \(fields): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot, let document = snapshot.documents.first {
                    do {
                        let userDto = try document.data(as: UserDto.self)
                        continuation.resume(returning: userDto)
                    } catch {
                        NSLog("LOG: Failed to convert Firestore document to UserDto: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                } else {
                    // No matching document found
                    NSLog("LOG: No matching user found for fields: \(fields)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
//    func getFriendByPinFromFirebase(friendPin: String) async throws -> FriendRecord {
//        try await withCheckedThrowingContinuation { continuation in
//            usersCollection.whereField("pin", isEqualTo: friendPin).getDocuments { snapshot, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                }
//                
//                guard let documents = snapshot?.documents, let document = documents.first else {
//                    let error = NSError(domain: "getFriendIdByPinError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No such friend with pin: \(friendPin)"])
//                    continuation.resume(throwing: error)
//                    return
//                }
//                
//                do {
//                    let userDto = try document.data(as: UserDto.self)
//                    let friendRecord = await convertUserDtoToFriendRecord(userDto: userDto)
//                    continuation.resume(returning: friendRecord)
//                } catch {
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }

    
    func getFriendIdByPinFromFirebase(friendPin: String) async throws -> String {
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

    
    // MARK: Stop using these functions, replace them with 'updateFriendListInFirebase'
    func addFriendIdInFirebase(friendId: String) {
        NSLog("LOG: RepositoryManager-addFriendIdInFirebase")
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
    
    // MARK: Stop using these functions, replace them with 'updateFriendListInFirebase'
    func removeFriendIdInFirebase(friendId: String) {
        guard let currentUserId = auth.currentUser?.uid else {
            NSLog("LOG: currentUserId is not set when removing friend id")
            return
        }
        
        let currentUserRef = usersCollection.document(currentUserId)
        currentUserRef.updateData([
            "friends": FieldValue.arrayRemove([friendId])
        ]) { error in
            if let error = error {
                NSLog("LOG: Failed to remove friend from Firestore: \(error.localizedDescription)")
            } else {
                NSLog("LOG: Successfully removed friend with id: \(friendId) from Firestore")
            }
        }
    }
    
    func updateFriendListInFirebase(documentId: String, friendId: String, action: ActionType) {
        NSLog("LOG: RepositoryManager-updateFriendListInFirebase")
        let userRef = usersCollection.document(documentId)
        
        let updateData: [String: Any]
        
        switch action {
        case .add:
            updateData = ["friends": FieldValue.arrayUnion([friendId])]
        case .remove:
            updateData = ["friends": FieldValue.arrayRemove([friendId])]
        }
        
        userRef.updateData(updateData) { error in
            if let error = error {
                NSLog("LOG: Failed to update friends list in Firestore: \(error.localizedDescription)")
            } else {
                let actionString = action == .add ? "added to" : "removed from"
                NSLog("LOG: Successfully \(actionString) friends list with id: \(friendId)")
            }
        }
    }
    
    func updateInvitationListInFirebase(documentId: String, friendId: String, action: ActionType, listType: InvitationListType) {
        let userRef = usersCollection.document(documentId)
        
        let updateData: [String: Any]
        let fieldName: String
        
        // Determine which list to update based on listType
        switch listType {
        case .received:
            fieldName = "receivedInvitations"
        case .sent:
            fieldName = "sentInvitations"
        }
        
        // Set the updateData based on the action (add or remove)
        switch action {
        case .add:
            updateData = [fieldName: FieldValue.arrayUnion([friendId])]
        case .remove:
            updateData = [fieldName: FieldValue.arrayRemove([friendId])]
        }
        
        // Update the Firestore document
        userRef.updateData(updateData) { error in
            if let error = error {
                NSLog("LOG: Failed to update \(fieldName) list in Firestore: \(error.localizedDescription)")
            } else {
                let actionString = action == .add ? "added to" : "removed from"
                NSLog("LOG: Successfully \(actionString) \(fieldName) list with id: \(friendId)")
            }
        }
    }

    enum ActionType {
        case add
        case remove
    }
    
    enum InvitationListType {
        case received
        case sent
    }

    
    func updateDeviceTokenInFirebase(userId: String, newDeviceToken: String) {
        usersCollection.document(userId).updateData([
            "deviceToken": newDeviceToken
        ]) { error in
            if let error = error {
                NSLog("LOG: Error updating device token in Firestore: \(error.localizedDescription)")
            } else {
//                NSLog("LOG: Device token successfully updated in Firestore")
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
//                NSLog("Successfully updated call request and room name for both user and friend.")
            }
        }
    }

}

// MARK: Firebase: Room document
extension RepositoryManager {
    
    // Function to remove all room documents associated with the current user
    func removeRoomsForCurrentUser() async {
        guard let currentUserId = userRecord?.id else {
            NSLog("LOG: No current user found to delete rooms")
            return
        }

        do {
            // Fetch all room documents where the user is either userId1 or userId2
            let roomsQuery1 = db.collection("rooms").whereField("userId1", isEqualTo: currentUserId)
            let roomsQuery2 = db.collection("rooms").whereField("userId2", isEqualTo: currentUserId)

            // Fetch and delete room documents where the current user is userId1
            let roomDocs1 = try await roomsQuery1.getDocuments()
            for document in roomDocs1.documents {
                let roomId = document.documentID
                try await deleteRoomDocument(roomId: roomId)
            }

            // Fetch and delete room documents where the current user is userId2
            let roomDocs2 = try await roomsQuery2.getDocuments()
            for document in roomDocs2.documents {
                let roomId = document.documentID
                try await deleteRoomDocument(roomId: roomId)
            }
            
            NSLog("LOG: Successfully deleted all rooms associated with current user.")
        } catch {
            NSLog("LOG: Failed to delete rooms associated with current user: \(error.localizedDescription)")
        }
    }

    // Helper function to delete a specific room document and clean up listeners
    private func deleteRoomDocument(roomId: String) async throws {
        let roomDocRef = db.collection("rooms").document(roomId)
        
        // Remove Firestore document
        try await roomDocRef.delete()
        NSLog("LOG: Room document \(roomId) deleted from Firestore.")
        
        // Optionally remove any listeners or related room data from local database
        stopListeningToRoom(roomId: roomId) // Assuming you have a function to stop listeners
    }
    
    // Placeholder function to stop listening to room
    private func stopListeningToRoom(roomId: String) {
        // Your logic to stop listeners for the room
        NSLog("LOG: Stopped listening to room \(roomId)")
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

extension RepositoryManager {
    func cleanUpUserData() {
        // Erase all user-related data here (friends, messages, etc.)
        eraseAllFriendsFromDatabase()
        eraseAllUsers()
        removeAllListeners()
        NSLog("LOG: User-related data cleaned up")
    }
}

extension RepositoryManager {
    func deleteUserFromFirebaseAuth(uid: String) async -> Bool {
        guard let url = URL(string: deleteUserByUIDUrl) else {
            NSLog("Failed to create URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = ["uid": uid]

        do {
            // Prepare the JSON body with the UID
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.httpBody = jsonData

            // Send the request to the Firebase Function
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check for a valid response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                NSLog("LOG: User successfully deleted from Firebase Authentication via function")
                return true
            } else {
                NSLog("LOG: Failed to delete user via function with response code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return false
            }
        } catch {
            NSLog("LOG: Failed to delete user via function: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Fetch User
extension RepositoryManager {
    func fetchUser(id: String) async throws {
        var newUserRecord: UserRecord?
        var needToUpdateLocalUserRecord = false
        
//        NSLog("LOG: Fetching user from local database")
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
            
//            NSLog("LOG: Fetching detailedFriends from local database")
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
//            NSLog("LOG: newDetailedFriends: \(newDetailedFriends)")
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
    
}

// MARK: Convert functions
extension RepositoryManager {
    private func convertUserDtoToUserRecord(userDto: UserDto) async throws -> UserRecord {
        var imageData: Data? = nil
        
        // Get profile image data from firebase storage
        if let profileImagePath = userDto.profileImagePath {
            let storageRef = storage.reference(forURL: profileImagePath)
            imageData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
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
        }
        
        let userRecord = UserRecord(
            id: userDto.id ?? UUID().uuidString,
            email: userDto.email,
            username: userDto.username,
            password: userDto.password,
            pin: userDto.pin,
            hasIncomingCallRequest: userDto.hasIncomingCallRequest,
            profileImageData: imageData,  // imageData will be nil if profileImagePath was nil
            deviceToken: userDto.deviceToken,
            friends: userDto.friends,
            socialLoginId: userDto.socialLoginId,
            socialLoginType: userDto.socialLoginType,
            imageOffset: userDto.imageOffset,
            receivedInvitations: userDto.receivedInvitations,
            sentInvitations: userDto.sentInvitations,
            status: userDto.status
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
            lastInteraction: roomDto?.lastInteraction.dateValue(),
            status: userDto.status
        )
        
        return friendRecord
    }
        enum RoomDocumentConvertError: Error {
        case missingField(String)
        case invalidDataType(String)
        case documentConversionFailed
    }
    
    func convertRoomDocumentToRoomDto(document: DocumentSnapshot) throws -> RoomDto {
        guard let data = document.data() else {
            throw RoomDocumentConvertError.documentConversionFailed
        }
        
        guard let userId1 = data["userId1"] as? String else {
            throw RoomDocumentConvertError.missingField("userId1")
        }
        
        guard let userId2 = data["userId2"] as? String else {
            throw RoomDocumentConvertError.missingField("userId2")
        }
        
        guard let timestamp = data["lastInteraction"] as? Timestamp else {
            throw RoomDocumentConvertError.invalidDataType("lastInteraction")
        }
        
        guard let nickname = data["nickname"] as? String else {
            throw RoomDocumentConvertError.missingField("nickname")
        }
        
        guard let isActive = data["isActive"] as? Int else {
            throw RoomDocumentConvertError.invalidDataType("isActive")
        }
        
        // Convert the Firestore Timestamp to a Date
        let date = timestamp.dateValue()
        
        // Create and return a RoomDto instance using the original initializer
        return RoomDto(id: document.documentID, userId1: userId1, userId2: userId2, lastInteraction: date, nickname: nickname, isActive: isActive)
    }

}

// MARK: update firebase on long press start/end
extension RepositoryManager {
    func updateFirebaseWhenLongPressStart(friendId: String) {
        // Get current timestamp
        let currentTimestamp = Date()
        
        // Get current user ID from 'userRecord'
        guard let currentUserId = userRecord?.id else {
            NSLog("LOG: currentUserId is not available when updating timestamp")
            return
        }
        
        // Just need to update timestamp value in firebase
        // Memory and Local db update will be handled by room listener
        
        // Get room id
        let roomId = RoomDto.generateRoomId(userId1: currentUserId, userId2: friendId)
        
        // Update 'lastInteraction' value in room document
//        updateTimestampInFirebase(roomId: roomId, currentTimestamp: currentTimestamp)
        
        // Get a reference to the room document
        let roomDocument = roomsCollection.document(roomId)
        
        // Update the 'lastInteraction' and 'isActive' field with the current timestamp
        roomDocument.updateData([
            "lastInteraction": currentTimestamp,
            "isActive": true,
        ]) { error in
            if let error = error {
                NSLog("LOG: Failed to update timestamp in Firebase: \(error.localizedDescription)")
            } else {
//                NSLog("LOG: Successfully updated timestamp in Firebase for roomId: \(roomId)")
            }
        }
    }
    
    func updateFirebaseWhenLongPressEnd(friendId: String) {
        // Get current user ID from 'userRecord'
        guard let currentUserId = userRecord?.id else {
            NSLog("LOG: currentUserId is not available when updating timestamp")
            return
        }
        
        // Just need to update timestamp value in firebase
        // Memory and Local db update will be handled by room listener
        
        // Get room id
        let roomId = RoomDto.generateRoomId(userId1: currentUserId, userId2: friendId)
        
        // Update 'lastInteraction' value in room document
//        updateTimestampInFirebase(roomId: roomId, currentTimestamp: currentTimestamp)
        
        // Get a reference to the room document
        let roomDocument = roomsCollection.document(roomId)
        
        // Update the 'isActive' field with the current timestamp
        roomDocument.updateData([
            "isActive": false,
        ]) { error in
            if let error = error {
                NSLog("LOG: Failed to update timestamp in Firebase: \(error.localizedDescription)")
            } else {
//                NSLog("LOG: Successfully updated timestamp in Firebase for roomId: \(roomId)")
            }
        }
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
                        let roomDto = try self.convertRoomDocumentToRoomDto(document: document)
//                        NSLog("LOG: Room document converted successfully to RoomDto in fetchRoomFromFirebase")
//                        print(roomDto)
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
//                NSLog("LOG: Successfully updated timestamp in Firebase for roomId: \(roomId)")
            }
        }
    }
    
    func removeRoomFromFirebase(roomId: String) {
        roomsCollection.document(roomId).delete { error in
            if let error = error {
                NSLog("LOG: Failed to remove room from Firebase: \(error.localizedDescription)")
            } else {
//                NSLog("LOG: Successfully removed room with id: \(roomId) from Firebase")
            }
        }
    }
}

extension RepositoryManager {
    func removeAllListeners() {
        // Cancel and remove all room listeners
        for listener in roomsListeners {
            listener.value.remove()
        }
        roomsListeners.removeAll()
        
        // Cancel and remove all friend listeners
        for listener in friendsListeners {
            listener.value.remove()
        }
        friendsListeners.removeAll()
        
        // Cancel and remove the user listener if it exists
        userListener?.remove()
        userListener = nil
        
        NSLog("LOG: Successfully removed all listeners")
    }
}

// MARK: Firestore update function
extension RepositoryManager {
    
    // MARK: General update function without completion handler
    func updateFieldInFirestore(collection: String, documentId: String, fieldsToUpdate: [String: Any]) {
//        NSLog("LOG: updateFieldInFirestore")
        db.collection(collection).document(documentId).updateData(fieldsToUpdate) { error in
            if let error = error {
                NSLog("LOG: Error updating document in Firestore: \(error.localizedDescription)")
            } else {
//                NSLog("LOG: Document successfully updated in Firestore")
            }
        }
    }
    
    // MARK: Update function for 'users' collection
    func updateUserField(userId: String, fieldsToUpdate: [String: Any]) {
//        NSLog("LOG: updateUserField")
        updateFieldInFirestore(collection: "users", documentId: userId, fieldsToUpdate: fieldsToUpdate)
    }

    // MARK: Update function for 'rooms' collection
    func updateRoomField(roomId: String, fieldsToUpdate: [String: Any]) {
        updateFieldInFirestore(collection: "rooms", documentId: roomId, fieldsToUpdate: fieldsToUpdate)
    }
}


enum UserState {
    case isSpeaking
    case isListening
    case idle
}
