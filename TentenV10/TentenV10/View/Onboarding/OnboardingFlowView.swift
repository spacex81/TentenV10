
import SwiftUI

enum OnboardingStep {
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
            case .username:
                UsernameView() {
                    viewModel.onboardingStep = .profileImage // Move to ProfileImageView
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .profileImage:
                ProfileImageView(
                    onNext: {
                        viewModel.onboardingStep = .addFriend // Move to AddView
                    },
                    onBack: {
                        viewModel.onboardingStep = .username // Go back to UsernameView
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .addFriend:
                ZStack {
                    AddView(
                        onNext: {
                            viewModel.isOnboardingComplete = true // Onboarding complete, move to Home
                        },
                        onBack: {
                            viewModel.onboardingStep = .profileImage // Go back to ProfileImageView
                        }
                    )
                    
                    if viewModel.showPopup {
                        InvitationView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),   // Appears from the right
                    removal: .move(edge: .leading)      // Disappears to the left
                ))
                
            case .home:
                ZStack {
                    HomeView()
                    
                    if viewModel.showPopup {
                        InvitationView()
                    }
                }
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
