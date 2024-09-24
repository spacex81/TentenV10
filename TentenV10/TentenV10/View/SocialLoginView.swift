
import SwiftUI

struct SocialLoginView: View {
    @ObservedObject var viewModel = AuthViewModel.shared

    let iconSize = 20.0

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            SignInButtonView(loginType: .apple, buttonText: "Sign in with Apple", iconSize: iconSize)
            SignInButtonView(loginType: .google, buttonText: "Sign in with Google", iconSize: iconSize)
            SignInButtonView(loginType: .kakao, buttonText: "Sign in with Kakao", iconSize: iconSize)
            SignInButtonView(loginType: .email, buttonText: "Sign in with Email", iconSize: iconSize)
            Spacer()
                .frame(height: 100)
        }
        .padding()
    }
}
