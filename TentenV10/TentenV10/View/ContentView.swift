//import SwiftUI
//import FirebaseAuth
//
//struct ContentView: View {
//    @ObservedObject var viewModel = ContentViewModel.shared
//
//    var body: some View {
//        NavigationStack {
//            if viewModel.isUserLoggedIn {
//                if viewModel.isOnboardingComplete {
//                    HomeView()
//                } else {
//                    OnboardingFlowView()
//                }
//            } else {
//                SocialLoginView()
//            }
//        }
//        .environmentObject(viewModel)
//    }
//}

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel.shared
    @State private var showEmailView = false // State to control EmailView presentation

    var body: some View {
        NavigationStack {
            ZStack {
                // Main app navigation flow
                if viewModel.isUserLoggedIn {
                    if viewModel.isOnboardingComplete {
                        HomeView()
                    } else {
                        OnboardingFlowView()
                    }
                } else {
                    // SocialLoginView with a transition
                    if !showEmailView {
                        SocialLoginView(showEmailView: $showEmailView)
                            .transition(.move(edge: .leading)) // Disappears to the left
                            .zIndex(0)
                    }
                    
                    // EmailView with coordinated transition
                    if showEmailView {
                        EmailView(showEmailView: $showEmailView)
                            .transition(.move(edge: .trailing)) // Appears from the right
                            .zIndex(1)
                    }
                }
            }
            .animation(.easeInOut, value: showEmailView) // Animate transitions
        }
        .environmentObject(viewModel)
    }
}
