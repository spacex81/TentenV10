import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel.shared

    var body: some View {
        NavigationStack {
            if viewModel.isUserLoggedIn {
                if viewModel.isOnboardingComplete {
                    HomeView()
                } else {
                    OnboardingFlowView()
                }
            } else {
                SocialLoginView()
            }
        }
        .environmentObject(viewModel)
    }
}
