import Foundation
import FirebaseCore
import GoogleSignIn

class TestContentViewModel: ObservableObject {
    static let shared = TestContentViewModel()
    
    @Published var email: String? = nil
    @Published var isLoggedIn: Bool = false
}

extension TestContentViewModel {
    func googleSignIn() async {
        print("LOG: handleGoogleSignIn")
        do {
            guard let user: GIDGoogleUser = try await GoogleSignInManager.shared.signInWithGoogle() else { return }
            
            print("LOG: Succeed to sign in with google login")
            print(user)
            
            // Accessing the email address
            if let email = user.profile?.email {
                print("User's email address: \(email)")
                DispatchQueue.main.async {
                    self.email = email
                    self.isLoggedIn = true
                }
            } else {
                print("Email address not available")
            }
        }
        catch {
            print("GoogleSignInError: failed to sign in with Google, \(error))")
            // Here you can show error message to user.
        }
    }
    
    func googleSignOut() {
        GoogleSignInManager.shared.signOutFromGoogle()
        DispatchQueue.main.async {
            self.email = nil
            self.isLoggedIn = false
        }
    }
}
