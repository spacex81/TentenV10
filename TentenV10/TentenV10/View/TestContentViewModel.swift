import Foundation
import FirebaseAuth
import AuthenticationServices
import FirebaseCore
import GoogleSignIn

class TestContentViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = TestContentViewModel()
    
    @Published var email: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var userID: String?
}

// MARK: Google sign in
extension TestContentViewModel {
    func googleSignIn() async {
        print("LOG: handleGoogleSignIn")
        do {
            guard let user: GIDGoogleUser = try await GoogleSignInManager.shared.signInWithGoogle() else { return }
            
            print("LOG: Succeeded to sign in with Google login")
            
            // Accessing the email address
            if let email = user.profile?.email {
                print("User's email address: \(email)")
                DispatchQueue.main.async {
                    self.userID = user.userID
                    self.email = email
                    self.isLoggedIn = true
                }
            } else {
                print("Email address not available")
            }
        }
        catch {
            print("GoogleSignInError: failed to sign in with Google, \(error))")
        }
    }
    
    func googleSignOut() {
        GoogleSignInManager.shared.signOutFromGoogle()
        DispatchQueue.main.async {
            self.email = nil
            self.userID = nil
            self.isLoggedIn = false
        }
    }
}

// MARK: Apple sign in
extension TestContentViewModel {
    func appleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func appleSignOut() {
        // Handle sign-out logic for Apple ID
        DispatchQueue.main.async {
            self.email = nil
            self.userID = nil
            self.isLoggedIn = false
        }
    }
    
    // MARK: ASAuthorizationControllerDelegate methods
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let email = appleIDCredential.email
//            let fullName = appleIDCredential.fullName
            
            DispatchQueue.main.async {
                self.userID = userID
                self.email = email
                self.isLoggedIn = true
            }
            
            print("Apple Sign In succeeded, User ID: \(userID), Email: \(email ?? "N/A")")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign In failed: \(error.localizedDescription)")
    }
    
    // MARK: ASAuthorizationControllerPresentationContextProviding method
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: Kakao sign in
extension TestContentViewModel {
    func kakaoSignIn() {
        // Handle Kakao Sign-In
    }
    
    func kakaoSignOut() {
        // Handle Kakao Sign-Out
        DispatchQueue.main.async {
            self.email = nil
            self.userID = nil
            self.isLoggedIn = false
        }
    }
}
