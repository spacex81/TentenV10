import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    @State private var isLoginMode = true
    
    var body: some View {
        if viewModel.isUserLoggedIn {
            HomeView()
                .environmentObject(viewModel)
                .onAppear {
                    if let id = Auth.auth().currentUser?.uid {
                        NSLog("LOG: fetch user record on appear")
                        viewModel.fetchUser(id: id)
                    }
                }
        } else {
            AuthView(isLoginMode: $isLoginMode)
                .environmentObject(viewModel)
        }
    }
}
