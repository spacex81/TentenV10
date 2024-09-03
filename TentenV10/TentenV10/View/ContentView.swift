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
    
    var body: some View {
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

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
