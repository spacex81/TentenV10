import SwiftUI

struct ContentView: View {
    @ObservedObject var authViewModel = AuthViewModel()
    @ObservedObject var homeViewModel = HomeViewModel()

    var body: some View {
        Group {
            if authViewModel.user == nil {
                AuthView(viewModel: authViewModel)
            } else {
                HomeView(viewModel: homeViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
