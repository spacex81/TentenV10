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
    func signIn(email: String, password: String) {
       NSLog("LOG: signIn")
       auth.signIn(withEmail: email, password: password) { result, error in
           if let error = error {
               NSLog("LOG: Failed to sign in: \(error.localizedDescription)")
           } else {
               NSLog("LOG: Succeed to sign in")
           }
       }
   }
    
    func signUp(email: String, password: String, completion: @escaping (AuthDataResult) -> Void) {
        NSLog("LOG: signUp")
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                NSLog("LOG: Failed to sign up: \(error.localizedDescription)")
            } else {
                NSLog("LOG: Succeed to sign up")
                guard let result = result else {
                    NSLog("LOG: result is null when signUp")
                    return
                }
                
                completion(result)
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

// MARK: Firestore
extension FirebaseManager {
    func createUser(userDto: UserDto) {
        do {
            try db.collection("users").document(userDto.id!).setData(from: userDto) { error in
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
    
    func fetchUser(userId: String, completion: @escaping (UserDto) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                do {
                    let userDto = try document.data(as: UserDto.self)
                    completion(userDto)
                } catch {
                    NSLog("LOG: failed to convert firestore document to UserDto: \(error.localizedDescription)")
                }
            } else {
                NSLog("LOG: failed to fetch user dto from firestore")
                self.signOut()
            }
        }
    }
    
    func getFriendIdByPin(friendPin: String, completion: @escaping (String) -> Void) {
        usersCollection.whereField("pin", isEqualTo: friendPin).getDocuments { (snapshot, error) in
            if let error = error {
                NSLog("LOG: Error fetching friend: \(error.localizedDescription)")
            }

            guard let documents = snapshot?.documents, let document = documents.first else {
                NSLog("LOG: No such friend with pin: \(friendPin)")
                return
            }

            let friendId = document.documentID
            completion(friendId)
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
}

// MARK: Storage
extension FirebaseManager {
    func uploadImage(id: String, profileImageData: Data, completion: @escaping (String) -> Void) {
        let storageRef = storage.reference().child("profile_images").child("\(id).jpg")
        storageRef.putData(profileImageData, metadata: nil) { metadata, error in
            if let error = error {
                NSLog("LOG: Failed to Store Profile Image to Firebase Storage: \(error)")
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    NSLog("LOG: Failed to Get Profile Image Url from Firebase Storage: \(error)")
                }
                
                if let url = url {
                    completion(url.absoluteString)
                }
            }
        }
    }
    
    func updateDeviceToken(userId: String, newDeviceToken: String) {
        db.collection("users").document(userId).updateData([
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
