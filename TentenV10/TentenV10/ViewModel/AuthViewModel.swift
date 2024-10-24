import Foundation
import UIKit
import FirebaseAuth
import AuthenticationServices
import FirebaseCore
import GoogleSignIn

import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

class AuthViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AuthViewModel()
    
    private let authManager = AuthManager.shared
    private let repoManager = RepositoryManager.shared
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMsg: String = ""
    @Published var selectedImage: UIImage?
    
    @Published var deviceToken: String? {
        didSet {
            if let deviceToken = deviceToken {
                NSLog("LOG: AuthViewModel-deviceToken: \(deviceToken)")
            }
        }
    }
    
    @Published var socialLoginId: String = ""
    @Published var socialLoginType: String = ""
    @Published var username: String = "default"
    
    @Published var isLoading: [SocialLoginType: Bool] = [:]
    
    @Published var showEmailView: Bool = false
    
    // MARK: Permission status
    @Published var isNotificationPermissionGranted = true
    @Published var isMicPermissionGranted = true
    //
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceTokenNotification(_:)), name: .didReceiveDeviceToken, object: nil)
    }
    
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        if let token = notification.userInfo?["deviceToken"] as? String {
            self.deviceToken = token
        }
    }
}

extension AuthViewModel {
    // MARK: Decide to run `signIn()` or `signUp()`
    func authenticate(for loginType: SocialLoginType) {
        Task {
            NSLog("LOG: AuthViewModel-authenticate()")
            do {
                let firebaseToken = try await authManager.fetchFirebaseToken(socialLoginId: socialLoginId, socialLoginType: socialLoginType)

                let userDto =  try await repoManager.fetchUserFromFirebase(field: "socialLoginId", value: socialLoginId)
                if userDto?.socialLoginType == self.socialLoginType &&
                   userDto?.socialLoginId == self.socialLoginId
                {
                    NSLog("LOG: Signing in")
                    authManager.isOnboardingComplete = true
                    signIn(firebaseToken: firebaseToken)
                    stopLoading(for: loginType)
                } else {
                    NSLog("LOG: Signing up")
                    authManager.isOnboardingComplete = false
                    authManager.onboardingStep = .username
                    signUp(firebaseToken: firebaseToken)
                    stopLoading(for: loginType)
                }

            } catch {
                NSLog("LOG: Error when fetching user from firebase using socialLoginId value")
            }
       
        }
    }
    
    func signIn(firebaseToken: String) {
        // Check if user logged in with same account
        if let _ = repoManager.readUserFromDatabase(email: email) {
            DispatchQueue.main.async {
                self.repoManager.needUserFetch = false
            }
        } else {
            // If user logged in with different account than set 'needUserFetch' to true
            // erase current content of user table and friend table
            
            // Clean up account
            HomeViewModel.shared.username = ""
            HomeViewModel.shared.profileImageData = nil
            HomeViewModel.shared.imageOffset = 0.0
            repoManager.userRecord = nil
            repoManager.detailedFriends = []
            repoManager.selectedFriend = nil
            repoManager.removeAllListeners()
            repoManager.eraseAllUsers()
            repoManager.eraseAllFriendsFromDatabase()
            //
            DispatchQueue.main.async {
                self.repoManager.needUserFetch = true
            }
            
        }
        
        Task {
            do {
                let user = try await authManager.signIn(withCustomToken: firebaseToken)
                try await repoManager.fetchUser(id: user.uid)
            } catch {
                NSLog("Failed to sign in: \(error.localizedDescription)")
            }
        }
    }
    
    func signUp(firebaseToken: String) {
        
        // Clean up account
        NSLog("LOG: Cleaning up previous account")
        HomeViewModel.shared.username = ""
        HomeViewModel.shared.profileImageData = nil
        HomeViewModel.shared.imageOffset = 0.0
        repoManager.userRecord = nil
        repoManager.detailedFriends = []
        repoManager.selectedFriend = nil
        repoManager.removeAllListeners()
        repoManager.eraseAllUsers()
        repoManager.eraseAllFriendsFromDatabase()
        //

        DispatchQueue.main.async {
            self.repoManager.needUserFetch = false
        }
        Task {
            do {
                let user = try await authManager.signIn(withCustomToken: firebaseToken)
                let id = user.uid

                // Skip username onboarding step if username is already set
//                if username != "default" {
//                }
                
                if socialLoginType == "apple" {
                    authManager.onboardingStep = .profileImage
                }
                
                let pin = generatePin()
                
                let newUserRecord = UserRecord(id: id, email: email, username: username, password: password, pin: pin, deviceToken: deviceToken, socialLoginId: socialLoginId, socialLoginType: socialLoginType)
                
                await repoManager.createUserWhenSignUp(newUserRecord: newUserRecord)
            } catch {
                NSLog("Error signing up user: \(error.localizedDescription)")
            }
        }
    }

    func signOut() {
        NSLog("LOG: signOut")
        DispatchQueue.main.async {
            self.repoManager.userRecord = nil
            self.repoManager.detailedFriends = []
            self.email = ""
            self.password = ""
        }
        authManager.signOut()
    }
}


// MARK: Google sign in
extension AuthViewModel {
    func googleSignIn() async {
        print("LOG: handleGoogleSignIn")
        do {
            guard let user: GIDGoogleUser = try await GoogleSignInManager.shared.signInWithGoogle() else { return }
            
            print("LOG: Succeeded to sign in with Google login")
            
            DispatchQueue.main.async {
                self.socialLoginId = user.userID ?? ""
                self.socialLoginType = "google"
                
                self.authenticate(for: .google)
            }
            

            // Accessing the email address
            if let email = user.profile?.email {
                print("User's email address: \(email)")
                DispatchQueue.main.async {
                    self.email = email
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
            self.email = ""
            self.socialLoginId = ""
            self.socialLoginType = ""
        }
    }
}

// MARK: Apple sign in
extension AuthViewModel {
    func appleSignIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: ASAuthorizationControllerDelegate methods
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let email = appleIDCredential.email
            
            // Full name (optional, only on first sign-in)
            let fullName = appleIDCredential.fullName
            NSLog("LOG: AuthViewModel-authorizationController: email: \(String(describing: email))")
            NSLog("LOG: AuthViewModel-authorizationController: fullName: \(String(describing: fullName))")

            
            DispatchQueue.main.async {
                self.socialLoginId = userID
                self.socialLoginType = "apple"
                self.email = email ?? ""
                self.username = fullName?.familyName ?? "default"
                
                self.authenticate(for: .apple)
            }
            
            print("Apple Sign In succeeded, User ID: \(userID), Email: \(email ?? "N/A")")
        }
    }
    
    
    
    func appleSignOut() {
        DispatchQueue.main.async {
            self.email = ""
            self.socialLoginId = ""
            self.socialLoginType = ""
        }
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error or cancellation and stop the loading spinner
        DispatchQueue.main.async {
            self.isLoading[.apple] = false // Reset loading state on error or cancellation
        }
        
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
extension AuthViewModel {
    func kakaoSignIn() {
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
            self.email = ""
            self.socialLoginId = ""
            self.socialLoginType = ""
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
                    self.socialLoginId = "\(String(describing: userID ?? 1234567890))"
                    self.socialLoginType = "kakao"
                    self.email = userEmail ?? ""
                    
                    self.authenticate(for: .kakao)
                }
            }
        }
    }
}

// MARK: Email sign in
extension AuthViewModel {
    func emailSignIn() {
        Task {
            // Wait for error checking to complete before proceeding
            let hasError = await checkErrorCases()
            
            // Only proceed with authentication if no errors were detected
            if !hasError {
                DispatchQueue.main.async {
                    self.socialLoginId = generateHash(from: self.email)
                    self.socialLoginType = "email"
                    self.errorMsg = "" 
                    
                    self.showEmailView = false
                    self.authenticate(for: .email)
                }
            }
        }
    }

    private func checkErrorCases() async -> Bool {
        // Error Case 1
        if email.isEmpty {
            errorMsg = "이메일을 입력해주세요."
            stopLoading(for: .email)
            return true
        }

        // Error Case 2
        if password.isEmpty {
            errorMsg = "비밀번호를 입력해주세요."
            stopLoading(for: .email)
            return true
        }

        // Error Case 3
        if !isValidEmail(email) {
            errorMsg = "이메일 형식이 올바르지 않습니다."
            stopLoading(for: .email)
            return true
        }

        // Check against Firebase for existing user with the email
        do {
            let userDto = try await repoManager.fetchUserFromFirebase(field: "email", value: email)

            // Error Case 4: Password mismatch
            if let userDto = userDto, userDto.password != password, userDto.socialLoginType == "email" {
                errorMsg = "이메일이 이미 사용 중 이거나, 비밀번호가 올바르지 않습니다."
                stopLoading(for: .email)
                return true
            }
        } catch {
            NSLog("LOG: emailSignIn - Error fetching user data from Firebase.")
            errorMsg = "서버 오류가 발생했습니다. 다시 시도해주세요." // Optional: Provide a user-friendly error message
            stopLoading(for: .email)
            return true
        }
        
        return false // No errors found
    }
    
    func emailSignOut() {
        DispatchQueue.main.async {
            self.email = ""
            self.socialLoginId = ""
            self.socialLoginType = ""
        }
    }
}

// MARK: Utils
extension AuthViewModel {
    private func generatePin() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<7).map { _ in letters.randomElement()! })
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Determine the scaling factor that preserves aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)

        // Compute the new size that preserves aspect ratio
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension AuthViewModel {
    func stopLoading(for loginType: SocialLoginType) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading[loginType] = false
        }
    }
}

extension AuthViewModel {
    func checkPermissions() async {
        NSLog("LOG: AuthViewModel-checkPermissions")
//        Task {
            // Check if notification permission is granted
            isNotificationPermissionGranted = await AuthManager.shared.isNotificationPermissionGranted()

            // Check if microphone permission is granted
            isMicPermissionGranted = await AuthManager.shared.isMicPermissionGranted()

            // Log the permission statuses
            print("Notification Permission Granted: \(isNotificationPermissionGranted)")
            print("Microphone Permission Granted: \(isMicPermissionGranted)")
//        }
    }
}

extension AuthViewModel {
    func deleteAccount() {
        Task {
            await repoManager.deleteCurrentUser()
        }
    }
}
