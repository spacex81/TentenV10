import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared

    @State private var isNotificationPermissionGranted = true
    @State private var isMicPermissionGranted = true

    var body: some View {
        NavigationStack {
            ZStack {
                // Main app navigation flow
                if viewModel.isUserLoggedIn {
                    // Check permissions when the user is logged in
                    if isNotificationPermissionGranted && isMicPermissionGranted {
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
                        if !isNotificationPermissionGranted {
                            NotificationPermissionView {
                                checkPermissions() // Recheck permissions after requesting
                            }
                        } else if !isMicPermissionGranted {
                            MicPermissionView {
                                checkPermissions() // Recheck permissions after requesting
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
            // Check permissions when the view appears
            checkPermissions()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
//                viewModel.generateInvitations()
//                viewModel.showPopup = true
//            })
        }
        .environmentObject(viewModel)
    }

    private func checkPermissions() {
        Task {
            // Check if notification permission is granted
            isNotificationPermissionGranted = await AuthManager.shared.isNotificationPermissionGranted()

            // Check if microphone permission is granted
            isMicPermissionGranted = await AuthManager.shared.isMicPermissionGranted()

            // Log the permission statuses
//            print("Notification Permission Granted: \(isNotificationPermissionGranted)")
//            print("Microphone Permission Granted: \(isMicPermissionGranted)")
        }
    }
}
