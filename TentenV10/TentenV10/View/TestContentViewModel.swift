import Foundation
import FirebaseAuth
import AuthenticationServices
import FirebaseCore
import GoogleSignIn

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

class TestContentViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = TestContentViewModel()
    
    @Published var email: String? = nil
    @Published var isLoggedIn: Bool = false
    @Published var userID: String? {
        didSet {
            print(userID ?? "Empty user id")
        }
    }
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
        if (UserApi.isKakaoTalkLoginAvailable()) {
            // MARK: Via app
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    print(error)
                }
                if let oauthToken = oauthToken{
//                    print("Login in with KakaoTalk success")
                    self.fetchKakaoUserInfo(oauthToken: oauthToken)
                }
            }
        } else {
            // MARK: Via webview
            UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                if let error = error {
                    print(error)
                }
                if let oauthToken = oauthToken{
//                    print("Login in with KakaoTalk account success")
                    self.fetchKakaoUserInfo(oauthToken: oauthToken)
                }
            }
        }
    }
    
    func kakaoSignOut() {
        // Handle Kakao Sign-Out
        DispatchQueue.main.async {
            self.email = nil
            self.userID = nil
            self.isLoggedIn = false
        }
    }
    
    func fetchKakaoUserInfo(oauthToken: OAuthToken) {
        UserApi.shared.me { (user, error) in
            if let error = error {
                print("Failed to get user info: \(error.localizedDescription)")
            } else if let user = user {
                // Here you can access the user's unique ID
                let userID = user.id
                let userEmail = user.kakaoAccount?.email
                
                print("User ID: \(String(describing: userID))")
                print("User Email: \(userEmail ?? "No email provided")")
                
                // Now you can save userID to your database to identify the user
                DispatchQueue.main.async {
                    self.userID = "\(String(describing: userID))"
                    self.email = userEmail
                    self.isLoggedIn = true
                }
            }
        }
    }
}
