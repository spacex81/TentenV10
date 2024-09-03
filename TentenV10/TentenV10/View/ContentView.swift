//import SwiftUI
//import FirebaseAuth
//
//struct ContentView: View {
//    @ObservedObject var viewModel = ContentViewModel()
//    
//    var body: some View {
//        VStack {
//            if viewModel.isUserLoggedIn {
//                HomeView()
//            } else {
//                AuthView()
//            }
//        }
//        .environmentObject(viewModel)
//    }
//}
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    let iconSize = 20.0
    
    @ObservedObject var viewModel = TestContentViewModel.shared

    var body: some View {
        if viewModel.isLoggedIn {
            VStack {
                // Email text
                if let email = viewModel.email {
                    Text("Logged in as: \(email)")
                } else {
                    Text("Email is not set")
                }
                
                // Sign out button
                Button {
                    viewModel.googleSignOut()
                } label: {
                    Text("Sign Out")
                }
            }
        } else {
            VStack(alignment: .leading) {
                Spacer()
                SignInButtonView(loginType: .apple, buttonText: "Sign in with Apple", iconSize: iconSize)
                SignInButtonView(loginType: .google, buttonText: "Sign in with Google", iconSize: iconSize)
                SignInButtonView(loginType: .kakao, buttonText: "Sign in with Kakao", iconSize: iconSize)
                Spacer()
                    .frame(height: 100)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
