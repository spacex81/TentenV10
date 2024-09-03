import SwiftUI
import FirebaseAuth

enum SocialLoginType: String {
    case apple = "apple"
    case google = "google"
    case kakao = "kakao"
    
    var iconName: String {
        return self.rawValue
    }
}

struct SignInButtonView: View {
    let loginType: SocialLoginType
    let buttonText: String
    let iconSize: CGFloat
    
    var body: some View {
        Button {
            handleSocialLogin(for: loginType)
        } label: {
            HStack {
                Image(loginType.iconName)
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .offset(x: loginType == .google ? 5 : 0)
                Text(buttonText)
                    .font(.headline)
                    .padding(.leading, 8)
            }
            .padding(15)
            .frame(width: UIScreen.main.bounds.width * 0.8)
            .foregroundColor(.black)
            .background(Color.white)
            .cornerRadius(25)
        }
        .padding(.bottom, 5)
    }
    
    private func handleSocialLogin(for loginType: SocialLoginType) {
        switch loginType {
        case .apple:
            // Handle Apple login
            print("Handle Apple login")
        case .google:
            // Handle Google login
            print("Handle Google login")
        case .kakao:
            // Handle Kakao login
            print("Handle Kakao login")
        }
    }
}

#Preview {
    VStack {
        SignInButtonView(loginType: .apple, buttonText: "Sign in with Apple", iconSize: 20)
            .preferredColorScheme(.dark)
        
        SignInButtonView(loginType: .google, buttonText: "Sign in with Google", iconSize: 20)
            .preferredColorScheme(.dark)
        
        SignInButtonView(loginType: .kakao, buttonText: "Sign in with Kakao", iconSize: 20)
            .preferredColorScheme(.dark)
    }
}
