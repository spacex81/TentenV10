import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    let usersCollection: CollectionReference
    
    init() {
        usersCollection = db.collection("users")
    }
}

// MARK: Auth
extension FirebaseManager {
    func signIn(email: String, password: String) async throws -> User {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User, Error>) in
            auth.signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let user = result?.user {
                    continuation.resume(returning: user)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred on sign in."]))
                }
            }
        }
    }
    
    func signUp(email: String, password: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            auth.createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    NSLog("LOG: Failed to sign up: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let user = result?.user {
                    NSLog("LOG: Succeed to sign up")
                    continuation.resume(returning: user)
                } else {
                    NSLog("LOG: Result is null when signUp")
                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."]))
                }
            }
        }
    }
    
    func signOut() {
        NSLog("LOG: signOut")
        do {
            try auth.signOut()
        } catch {
            NSLog("LOG: Failed to sign out")
        }
    }
}

// MARK: Firestore
extension FirebaseManager {
    func createUser(userDto: UserDto) {
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
    
    func fetchUser(userId: String) async throws -> UserDto {
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
    
    func getFriendByPin(friendPin: String) async throws -> String {
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
    
    func addFriendId(friendId: String) {
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
    
    func updateDeviceToken(userId: String, newDeviceToken: String) {
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
}

// MARK: Storage
extension FirebaseManager {
    func uploadImage(id: String, profileImageData: Data) async throws -> String {
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
