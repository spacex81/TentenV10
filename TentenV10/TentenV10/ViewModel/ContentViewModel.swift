import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GRDB

class ContentViewModel: ObservableObject {
    static let shared = ContentViewModel()
    private var dbQueue: DatabaseQueue!
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    @Published var selectedImage: UIImage?
    @Published var isUserLoggedIn = false
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var userRecord: UserRecord? {
        didSet {
            NSLog("LOG: userRecord didSet")
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
        }
    }
    @Published var friendsDetails: [FriendRecord] = []
    
    @Published var friendPin: String = ""
    
    private var deviceToken: String? {
        didSet {
            NSLog("LOG: userRecord didSet")
            if let deviceToken = deviceToken, let userRecord = userRecord {
                if userRecord.deviceToken != deviceToken {
                    updateDeviceToken(oldUserRecord: userRecord, newDeviceToken: deviceToken)
                }
            }
        }
    }
    
    private func updateDeviceToken(oldUserRecord: UserRecord, newDeviceToken: String) {
        var newUserRecord = oldUserRecord
        newUserRecord.deviceToken = newDeviceToken

        // update device token in self.userRecord
        self.userRecord = newUserRecord
        // update local database
        addUserToDatabase(user: newUserRecord)
        // update firestore
        updateDeviceTokenInFirestore(userId: newUserRecord.id, newDeviceToken: newDeviceToken)
//        let userDto = convertUserRecordToUserDto(userRecord: newUserRecord)
//        addUserToFirestore(user: userDto)
    }
    
    private func updateDeviceTokenInFirestore(userId: String, newDeviceToken: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "deviceToken": newDeviceToken
        ]) { error in
            if let error = error {
                print("Error updating device token in Firestore: \(error.localizedDescription)")
            } else {
                print("Device token successfully updated in Firestore")
            }
        }
    }

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        NSLog("ContentViewModel init")
        startListeningToAuthChanges()
        setupDatabase()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
    }
    
    
    deinit {
        stopListeningToAuthChanges()
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
    }
    
    func startListeningToAuthChanges() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.isUserLoggedIn = user != nil
        }
    }
    
    func stopListeningToAuthChanges() {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
}

// MARK: database
extension ContentViewModel {
    private func setupDatabase() {
        do {
            let databaseURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("db.sqlite")
            
            dbQueue = try DatabaseQueue(path: databaseURL.path)

            // Register migrations
            var migrator = DatabaseMigrator()

            migrator.registerMigration("v1") { db in
                // Create the initial users table
                try db.create(table: "users") { t in
                    t.column("id", .text).primaryKey()
                    t.column("email", .text).notNull()
                    t.column("username", .text).notNull()
                    t.column("pin", .text).notNull()
                    t.column("hasIncomingCallRequest", .boolean).notNull().defaults(to: false)
                    t.column("profileImageData", .blob)
                    t.column("deviceToken", .text)
                    t.column("friends", .text)
                }
                
                // Create the friends table
                try db.create(table: "friends") { t in
                    t.column("id", .text).primaryKey()
                    t.column("email", .text).notNull()
                    t.column("username", .text).notNull()
                    t.column("pin", .text).notNull()
                    t.column("profileImageData", .blob)
                    t.column("deviceToken", .text)
                    t.column("userId", .text).notNull().references("users", onDelete: .cascade) // Foreign key reference to users
                }
            }
            
            // Migrate the database to the latest version
            try migrator.migrate(dbQueue)
        } catch {
            NSLog("LOG: Error setting up database: \(error)")
        }
    }
    
    func addUserToDatabase(user: UserRecord) {
        do {
            try dbQueue.write { db in
                try user.save(db)
            }
        } catch {
            print("Failed to save user: \(error)")
        }
        
        NSLog("LOG: Successfully added new user record")
        printUserTable()
    }
    
    func addFriendToDatabase(friend: FriendRecord) {
        do {
            try dbQueue.write { db in
                try friend.save(db)
            }
        } catch {
            print("Failed to save friend: \(error)")
        }
    }
    
    // first fetch user from database
    // second fetch user from firestore if local database doesn't have user record
    func fetchUser(id: String) {
        NSLog("Fetching user from database")
        do {
            let userRecord = try dbQueue.read { db in
                try UserRecord.fetchOne(db, key: id)
            }
            if userRecord == nil {
                NSLog("LOG: user record is not available in local database")
                NSLog("LOG: Fetching user from firestore")
                if let id = auth.currentUser?.uid {
                    db.collection("users").document(id).getDocument { document, error in
                        if let document = document, document.exists {
                            do {
                                let userDto = try document.data(as: UserDto.self)
                                self.convertUserDtoToUserRecord(userDto: userDto) { userRecord in
                                    self.userRecord = userRecord
                                    self.addUserToDatabase(user: userRecord)
                                    self.fetchFriendsDetails(friendIds: userRecord.friends)
                                }
                            } catch let error {
                                NSLog("LOG: failed to convert firestore document to UserDto: \(error.localizedDescription)")
                            }
                        } else {
                            NSLog("LOG: failed to fetch user dto from firestore")
                            do {
                                try self.auth.signOut()
                            } catch {
                                NSLog("LOG: failed to sign out")
                            }
                        }
                    }
       
                }
            } else {
                self.userRecord = userRecord
                self.fetchFriendsDetails(friendIds: userRecord!.friends)
            }
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }
    
    func fetchFriendsDetails(friendIds: [String]) {
        for friendId in friendIds {
            do {
                let friendRecord = try dbQueue.read { db in
                    try FriendRecord.fetchOne(db, key: friendId)
                }
                if let friendRecord = friendRecord {
                    friendsDetails.append(friendRecord)
                } else {
                    fetchFriendFromFirestore(friendId: friendId)
                }
            } catch {
                print("Failed to fetch friend: \(error)")
            }
        }
    }
    
    func fetchFriendFromFirestore(friendId: String) {
        db.collection("users").document(friendId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let userDto = try document.data(as: UserDto.self)
                    self.convertUserDtoToFriendRecord(userDto: userDto) { friendRecord in
                        self.friendsDetails.append(friendRecord)
                        self.addFriendToDatabase(friend: friendRecord)
                    }
                } catch let error {
                    NSLog("LOG: failed to convert firestore document to UserDto: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func convertUserDtoToFriendRecord(userDto: UserDto, completion: @escaping (FriendRecord) -> Void) {
        if let profileImageUrl = userDto.profileImagePath {
            let storageRef = Storage.storage().reference(forURL: profileImageUrl)
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error fetching image: \(error)")
                    let friendRecord = FriendRecord(
                        id: userDto.id ?? UUID().uuidString,
                        email: userDto.email,
                        username: userDto.username,
                        pin: userDto.pin,
                        profileImageData: nil,
                        deviceToken: userDto.deviceToken
                    )
                    completion(friendRecord)
                } else {
                    let friendRecord = FriendRecord(
                        id: userDto.id ?? UUID().uuidString,
                        email: userDto.email,
                        username: userDto.username,
                        pin: userDto.pin,
                        profileImageData: data,
                        deviceToken: userDto.deviceToken
                    )
                    completion(friendRecord)
                }
            }
        } else {
            let friendRecord = FriendRecord(
                id: userDto.id ?? UUID().uuidString,
                email: userDto.email,
                username: userDto.username,
                pin: userDto.pin,
                profileImageData: nil,
                deviceToken: userDto.deviceToken
            )
            completion(friendRecord)
        }
    }
    
    func addFriend() {
        if var newUserRecord = self.userRecord {
            let usersCollection = db.collection("users")
            
            usersCollection.whereField("pin", isEqualTo: friendPin).getDocuments { (snapshot, error) in
                if let error = error {
                    NSLog("LOG: Error fetching friend")
                }
                
                guard let documents = snapshot?.documents, let document = documents.first else {
                    NSLog("LOG: No such friend with pin: \(self.friendPin)")
                    return
                }
                
                let friendId = document.documentID
                
                if !newUserRecord.friends.contains(friendId) {
                    newUserRecord.friends.append(friendId)
                    
                    // update memory
                    self.userRecord = newUserRecord
                    // update local db
                    self.addUserToDatabase(user: newUserRecord)
                    // update remote firestore
                    if let currentUserId = self.auth.currentUser?.uid {
                        let currentUserRef = usersCollection.document(currentUserId)
                        currentUserRef.updateData([
                            "friends": FieldValue.arrayUnion([friendId])
                        ]) { error in
                            if let error = error {
                                NSLog("LOG: Failed to add friend to firestore")
                            }
                        }
                    }
                }
            }
        } else {
            NSLog("LOG: userRecord is nil when adding friend")
        }
    }
    
    private func addUserToFirebase(_ id: String, _ profileImageData: Data, _ email: String, _ username: String, _ pin: String, _ deviceToken: String) {
        let storageRef = self.storage.reference().child("profile_images").child("\(id).jpg")
        storageRef.putData(profileImageData, metadata: nil) { metadata, error in
            if let error = error {
                NSLog("LOG: Failed to Store Profile Image to Firebase Storage: \(error)")
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    NSLog("LOG: Failed to Get Profile Image Url from Firebase Storage: \(error)")
                }
                
                if let url = url {
                    // profileImagePath
                    let userDto = UserDto(id: id, email: email, username: username, pin: pin, profileImagePath: url.absoluteString, deviceToken: deviceToken)
                    // save user dto to remote firestore
                    self.addUserToFirestore(user: userDto)
                }
            }
        }
    }
}

// MARK: firebase
extension ContentViewModel {
    func addUserToFirestore(user: UserDto) {
        do {
            try db.collection("users").document(user.id!).setData(from: user) { error in
                if let error = error {
                    print("Error adding user to Firestore: \(error)")
                } else {
                    print("User successfully added to Firestore")
                }
            }
        } catch let error {
            print("Error encoding user: \(error)")
        }
    }
}
// MARK: auth
extension ContentViewModel {
     func signIn() {
        NSLog("LOG: signIn")
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                NSLog("LOG: Failed to sign in: \(error.localizedDescription)")
            } else {
                NSLog("LOG: Succeed to sign in")
            }
        }
    }
    
    
    func signUp() {
        NSLog("LOG: signUp")
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                NSLog("LOG: Failed to sign up: \(error.localizedDescription)")
            } else {
                NSLog("LOG: Succeed to sign up")
                // set user record in view model
                guard let id = result?.user.uid, let email = result?.user.email, let deviceToken = self.deviceToken else {
                    NSLog("LOG: id or email or deviceToken is nil")
                    return
                }
                
                let username = email.split(separator: "@").first.map(String.init) ?? "User"
                let pin = self.generatePin()
                let profileImageData = self.selectedImage?.jpegData(compressionQuality: 0.8)

                let userRecord = UserRecord(id: id, email: email, username: username, pin: pin, profileImageData: profileImageData, deviceToken: deviceToken)
                // store image to firebase storage
                guard let profileImageData = profileImageData else {
                    NSLog("LOG: profileImageData is not set")
                    return
                }
                
                // set user record in memory
                self.userRecord = userRecord
                // save user record to local database
                self.addUserToDatabase(user: userRecord)
                // save user to firebase
                self.addUserToFirebase(id, profileImageData, email, username, pin, deviceToken)
            }
        }
    }
    
    
    
    func signOut() {
        NSLog("LOG: signOut")
        do {
            try Auth.auth().signOut()
        } catch {
            NSLog("LOG: Failed to sign out")
        }
    }
   
}

// MARK: Utils
extension ContentViewModel {
    private func generatePin() -> String {
            let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
            return String((0..<7).map { _ in letters.randomElement()! })
    }
    
    func convertUserDtoToUserRecord(userDto: UserDto, completion: @escaping (UserRecord) -> Void) {
        // this function needs to be updated
        // UserDto have profileImageUrl
        // we need to retrieve the image from firestore, and save it as blob in local database
        if let profileImagePath = userDto.profileImagePath {
            let storageRef = self.storage.reference(forURL: profileImagePath)
            storageRef.getData(maxSize: 10 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error fetching image: \(error)")
                    let userRecord = UserRecord(
                        id: userDto.id ?? UUID().uuidString,
                        email: userDto.email,
                        username: userDto.username,
                        pin: userDto.pin,
                        hasIncomingCallRequest: userDto.hasIncomingCallRequest,
                        profileImageData: nil,
                        deviceToken: userDto.deviceToken,
                        friends: userDto.friends
                    )
                    completion(userRecord)
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
        } else {
            let userRecord = UserRecord(
                id: userDto.id ?? UUID().uuidString,
                email: userDto.email,
                username: userDto.username,
                pin: userDto.pin,
                hasIncomingCallRequest: userDto.hasIncomingCallRequest,
                profileImageData: nil,
                deviceToken: userDto.deviceToken,
                friends: userDto.friends
            )
            completion(userRecord)
        }
    }
    
    func printUserTable() {
        NSLog("LOG: printUserTable")
        do {
            try dbQueue.read { db in
                let userRecords = try UserRecord.fetchAll(db)
                for userRecord in userRecords {
                    print(userRecord)
                }
            }
        } catch {
            print("Failed to fetch user records: \(error)")
        }
    }
}
