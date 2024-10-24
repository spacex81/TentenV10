import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Main app navigation flow
                if viewModel.isUserLoggedIn {
                    // Check permissions when the user is logged in
                    if authViewModel.isNotificationPermissionGranted && authViewModel.isMicPermissionGranted {
                        // Show Home or Onboarding Flow based on the onboarding status
                        if viewModel.isOnboardingComplete {
                            ZStack {
                                HomeView()
                                
                                if viewModel.showPopup {
                                    InvitationView()
                                }
                            }
                        } else {
                            OnboardingFlowView()
                        }
                    } else {
                        // Show respective permission view if the permissions are not granted
                        if !authViewModel.isNotificationPermissionGranted {
                            NotificationPermissionView {
                                Task {
                                    await authViewModel.checkPermissions() // Recheck permissions after requesting
                                }
                            }
                        } else if !authViewModel.isMicPermissionGranted {
                            MicPermissionView {
                                Task {
                                    
                                    await authViewModel.checkPermissions() // Recheck permissions after requesting
                                }
                            }
                        }
                    }
                } else {
                    // SocialLoginView with a transition
                    if !authViewModel.showEmailView {
                        SocialLoginView()
                            .transition(.move(edge: .leading)) // Disappears to the left
                            .zIndex(0)
                    }
                    
                    // EmailView with coordinated transition
                    if authViewModel.showEmailView {
                        EmailView()
                            .transition(.move(edge: .trailing)) // Appears from the right
                            .zIndex(1)
                    }
                }
            }
            .animation(.easeInOut, value: authViewModel.showEmailView) // Animate transitions
        }
        .onAppear {
            NSLog("LOG: ContentView-onAppear")
            // Check permissions when the view appears
            Task {
                await authViewModel.checkPermissions()
            }
        }
        .environmentObject(viewModel)
    }
}
