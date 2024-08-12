import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isUserLoggedIn = false
    @Published var currentUser: User?
    
    let auth = Auth.auth()
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        startListeningToAuthChanges()
    }
    
    deinit {
        stopListeningToAuthChanges()
    }
    
    func startListeningToAuthChanges() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
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
            auth.removeStateDidChangeListener(handle)
        }
    }
}

extension AuthManager {
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
