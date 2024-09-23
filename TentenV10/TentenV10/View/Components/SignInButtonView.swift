import SwiftUI

enum SocialLoginType: String {
    case apple = "apple"
    case google = "google"
    case kakao = "kakao"
    case email = "email"
    
    var iconName: String {
        return self.rawValue
    }
}

struct SignInButtonView: View {
    let loginType: SocialLoginType
    let buttonText: String
    let iconSize: CGFloat
    
    @ObservedObject var viewModel = AuthViewModel.shared
    @Binding var showEmailView: Bool // Binding to control showing EmailView
    
    var body: some View {
        Button {
            handleSocialLogin(for: loginType)
        } label: {
            ZStack {
                // Main content
                HStack {
                    if !(viewModel.isLoading[loginType] ?? false) {
                        // Case 1: Logo and text
                        if loginType == .email {
                            Image(systemName: "envelope.fill")
                        } else {
                            Image(loginType.iconName)
                                .resizable()
                                .frame(width: iconSize, height: iconSize)
                                .offset(x: loginType == .google ? 5 : 0)
                        }
                        
                        Text(buttonText)
                            .font(.headline)
                            .padding(.leading, 8)
                    } else {
                        // Case 2: Loading spinner
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(1.2)
                    }
                }
                .padding(15)
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .foregroundColor(.black)
                .background(Color.white)
                .cornerRadius(25)
            }
        }
        .padding(.bottom, 5)
    }
    
    private func handleSocialLogin(for loginType: SocialLoginType) {
        switch loginType {
        case .apple:
            viewModel.isLoading[.apple] = true
            viewModel.appleSignIn()
        case .google:
            Task {
                viewModel.isLoading[.google] = true
                await viewModel.googleSignIn()
            }
        case .kakao:
            viewModel.isLoading[.kakao] = true
            viewModel.kakaoSignIn()
        case .email:
            showEmailView = true // Show EmailView when email button is clicked
        }
    }
}

#Preview {
    VStack {
        SignInButtonView(loginType: .apple, buttonText: "Sign in with Apple", iconSize: 20, showEmailView: .constant(false))
            .preferredColorScheme(.dark)
        
        SignInButtonView(loginType: .google, buttonText: "Sign in with Google", iconSize: 20, showEmailView: .constant(false))
            .preferredColorScheme(.dark)
        
        SignInButtonView(loginType: .kakao, buttonText: "Sign in with Kakao", iconSize: 20, showEmailView: .constant(false))
            .preferredColorScheme(.dark)
        
        SignInButtonView(loginType: .email, buttonText: "Sign in with Email", iconSize: 20, showEmailView: .constant(false))
            .preferredColorScheme(.dark)
    }
}
