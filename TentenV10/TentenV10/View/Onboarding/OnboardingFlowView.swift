import SwiftUI

enum OnboardingStep {
    case notificationPermission
    case micPermission
    case username
    case profileImage
    case addFriend
    case home
}

struct OnboardingFlowView: View {
    @ObservedObject var viewModel = ContentViewModel.shared
    
    private let repoManager = RepositoryManager.shared
    private let authManager = AuthManager.shared
    
    init() {
        // MARK: When onboarding stops in the middle and app is relaunched
        if let userRecord = repoManager.userRecord {
            // This code should not interfere the 'onboardingStep' value in the middle of onboarding process
            if viewModel.onboardingStep == .username || viewModel.onboardingStep == .home {
                if userRecord.username == "default" {
                    if authManager.previousOnboardingStep != .username {
                        authManager.onboardingStep = .username
                    }
                } else if userRecord.profileImageData == nil {
                    if authManager.previousOnboardingStep != .profileImage {
                        authManager.onboardingStep = .profileImage
                    }
                } else if userRecord.friends.count == 0 {
                    if authManager.previousOnboardingStep != .addFriend {
                        authManager.onboardingStep = .addFriend
                    }
                } else {
                    if authManager.previousOnboardingStep != .home {
                        authManager.onboardingStep = .home
                    }
                }
                authManager.previousOnboardingStep = authManager.onboardingStep
            }
        }
    }

    var body: some View {
        VStack {
            switch viewModel.onboardingStep {
            case .notificationPermission:
                NotificationPermissionView() {
                    DispatchQueue.main.async {
                        self.viewModel.onboardingStep = .micPermission
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .micPermission:
                MicPermissionView() {
                    DispatchQueue.main.async {
                        self.viewModel.onboardingStep = .username
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))

            case .username:
                UsernameView() {
                    viewModel.onboardingStep = .profileImage // Move to ProfileImageView
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .profileImage:
                ProfileImageView() {
                    viewModel.onboardingStep = .addFriend // Move to AddView
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .addFriend:
                AddView {
                    viewModel.onboardingStep = .home // Complete onboarding
                    viewModel.isOnboardingComplete = true 
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .home:
                HomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),   // Appears from the right
                        removal: .move(edge: .leading)      // Disappears to the left
                    ))
            }
        }
        .animation(.easeInOut, value: viewModel.onboardingStep)
    }
}

#Preview {
    OnboardingFlowView()
}
