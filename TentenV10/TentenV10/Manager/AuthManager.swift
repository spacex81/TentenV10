import Foundation
import FirebaseAuth
import FirebaseFirestore
import UserNotifications
import AVFoundation


class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isUserLoggedIn = true
    @Published var isOnboardingComplete = true
    @Published var previousOnboardingStep: OnboardingStep = .username
    @Published var onboardingStep: OnboardingStep = .username {
        didSet {
//            NSLog("LOG: AuthManager-onboardingStep: \(onboardingStep)")
        }
    }

    @Published var currentUser: User? {
        didSet {
            if let currentUserId = currentUser?.uid {
                if UIApplication.shared.applicationState != .background {
                    let db = Firestore.firestore()
                    db.collection("users").document(currentUserId).updateData(["status":"foreground"])
                }
            }
        }
    }
    
    let generateFirebaseTokenUrl = "https://asia-northeast3-tentenv9.cloudfunctions.net/generateFirebaseToken"
    
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

// MARK: Check permission
extension AuthManager {
    // Function to check if notification permission is granted
    func isNotificationPermissionGranted() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    // Function to check if microphone permission is granted
    func isMicPermissionGranted() async -> Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return AVAudioSession.sharedInstance().recordPermission == .granted
        }
    }
}

extension AuthManager {
    func fetchFirebaseToken(socialLoginId: String, socialLoginType: String) async throws -> String {
        guard let url = URL(string: generateFirebaseTokenUrl) else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = [
            "socialLoginId": socialLoginId,
            "socialLoginType": socialLoginType
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.httpBody = jsonData
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            
            if let token = json?["firebaseToken"] as? String {
                return token
            } else {
                throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase token not found in response"])
            }
        } catch {
            NSLog("Failed to fetch Firebase token: \(error)")
            throw error
        }
    }
}

extension AuthManager {
    func signIn(withCustomToken customToken: String) async throws -> User {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User, Error>) in
            Auth.auth().signIn(withCustomToken: customToken) { result, error in
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
//    func signIn(email: String, password: String) async throws -> User {
//        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<User, Error>) in
//            auth.signIn(withEmail: email, password: password) { result, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                } else if let user = result?.user {
//                    continuation.resume(returning: user)
//                } else {
//                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred on sign in."]))
//                }
//            }
//        }
//    }
    
//    func signUp(email: String, password: String) async throws -> User {
//        try await withCheckedThrowingContinuation { continuation in
//            auth.createUser(withEmail: email, password: password) { result, error in
//                if let error = error {
//                    NSLog("LOG: Failed to sign up: \(error.localizedDescription)")
//                    continuation.resume(throwing: error)
//                } else if let user = result?.user {
//                    NSLog("LOG: Succeed to sign up")
//                    continuation.resume(returning: user)
//                } else {
//                    NSLog("LOG: Result is null when signUp")
//                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred."]))
//                }
//            }
//        }
//    }
    
    func signOut() {
        NSLog("LOG: signOut")
        do {
            try auth.signOut()
        } catch {
            NSLog("LOG: Failed to sign out")
        }
    }
}
