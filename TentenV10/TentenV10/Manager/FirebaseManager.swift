import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage

class FirebaseManager: NSObject {
    static let shared = FirebaseManager()
    
    let auth = Auth.auth()
    let db = Firestore.firestore()
    private let storage = Storage.storage()
}

// MARK: Auth
extension FirebaseManager {
    func signIn(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }

    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try auth.signOut()
            completion(.success(()))
        } catch let signOutError as NSError {
            completion(.failure(signOutError))
        }
    }
}

// MARK: Firestore
extension FirebaseManager {
    func fetchUserById(_ userId: String, completion: @escaping (Result<UserDto, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: UserDto.self)
                    completion(.success(user))
                } catch let error {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            }
        }
    }

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
    
    func updateUser(user: UserDto, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = user.id else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID is nil"])))
            return
        }
        
        do {
            try db.collection("users").document(userId).setData(from: user)
            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }

    
    func addFriendByPin(currentUserId: String, friendPin: String, completion: @escaping (Result<String, Error>) -> Void) {
        let usersCollection = db.collection("users")
        
        usersCollection.whereField("pin", isEqualTo: friendPin).getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents, let document = documents.first else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user found with this PIN"])))
                return
            }
            
            let friendId = document.documentID
            let currentUserRef = usersCollection.document(currentUserId)
            
            currentUserRef.updateData([
                "friends": FieldValue.arrayUnion([friendId])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(friendId))
                }
            }
        }
    }

}

// MARK: Storage
extension FirebaseManager {
    func uploadProfileImage(uid: String, imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference().child("profile_images").child("\(uid).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("LOG: Failed to Store Profile Image to Firebase Storage: \(error)")
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("LOG: Failed to Get Profile Image Url from Firebase Storage: \(error)")
                    completion(.failure(error))
                    return
                }

                if let url = url {
                    completion(.success(url))
                }
            }
        }
    }
}
