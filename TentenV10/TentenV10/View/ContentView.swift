import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isUserLoggedIn {
                HomeView()
            } else {
                AuthView()
            }
        }
        .environmentObject(viewModel)
    }
}

