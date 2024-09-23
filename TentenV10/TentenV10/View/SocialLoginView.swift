
import SwiftUI

struct SocialLoginView: View {
    @ObservedObject var viewModel = AuthViewModel.shared
    @Binding var showEmailView: Bool // Binding to control visibility of EmailView

    let iconSize = 20.0

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            SignInButtonView(loginType: .apple, buttonText: "Sign in with Apple", iconSize: iconSize, showEmailView: $showEmailView)
            SignInButtonView(loginType: .google, buttonText: "Sign in with Google", iconSize: iconSize, showEmailView: $showEmailView)
            SignInButtonView(loginType: .kakao, buttonText: "Sign in with Kakao", iconSize: iconSize, showEmailView: $showEmailView)
            SignInButtonView(loginType: .email, buttonText: "Sign in with Email", iconSize: iconSize, showEmailView: $showEmailView)
            Spacer()
                .frame(height: 100)
        }
        .padding()
    }
}
