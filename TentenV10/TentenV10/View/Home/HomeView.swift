import SwiftUI
import RiveRuntime

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared

    // Rive
    let shimmerViewModel = RiveViewModel(fileName: "shimmer", stateMachineName: "State Machine")
    let lockViewModel = RiveViewModel(fileName: "lock", stateMachineName: "State Machine")
    @State private var scale: CGFloat = 1.0 // State to track the lock icon's scale
    //
    
    let repoManager = RepositoryManager.shared
    let notificationManager = NotificationManager.shared(repoManager: RepositoryManager.shared, authManager: AuthManager.shared)

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Size of the collection view item
    var itemSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let standardItemSpacing: CGFloat = 10
        let totalSpacing = standardItemSpacing * 2 // 2 gaps of 10 points each
        return (screenWidth - totalSpacing) / 3.0
    }
    
    var strokeSize: CGFloat {
        return itemSize * 1.05
    }
    
    private var ringAnimationState: Bool {
        viewModel.isPressing || viewModel.isLocked
    }
    
    private var bounceAnimation: Animation {
        Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.0)
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                // Main text
                if let selectedFriend = repoManager.selectedFriend {
                    if viewModel.isPressing && !viewModel.isPublished {
                        ShimmeringViewControllerRepresentable(text: "Connecting", font: UIFont.boldSystemFont(ofSize: 24), fontSize: 24)
                            .frame(width: 200, height: 30)
                            .transition(.opacity)
                    } else if viewModel.isPressing && viewModel.isPublished && !viewModel.isLocked {
                        ShimmeringViewControllerRepresentable(text: "Slide up to lock", font: UIFont.boldSystemFont(ofSize: 24), fontSize: 24)
                        
                            .frame(width: 200, height: 30)
                            .transition(.opacity)
                    } else {
                        HStack {
                            Button {
                                impactFeedback.impactOccurred()
//                                notificationManager.sendRemoteNotification(type: "poke")
                                if let receiverToken = repoManager.selectedFriend?.deviceToken {
                                    notificationManager.sendRemoteNotification(type: "poke", receiverToken: receiverToken)
                                }
                            } label: {
                                Text("👋")
                                   .font(.system(size: 40, weight: .bold, design: .default))
                                   .baselineOffset(-10) // Adjust this value to move the emoji down
                            }

                            // Add distance in the middle
                            Text(selectedFriend.username)
                                .font(.system(size: 40, weight: .bold, design: .default))
                                .padding(.leading, 10) // Adjust the spacing between the emoji and the text
                                .padding(.top, 10)
                                .transition(.opacity)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 2, y: 2)
                        }
                   }
                }
            }
            
            ZStack {
                // Speech bubble
                if !viewModel.isPressing && !viewModel.isLocked {
                    if viewModel.currentState == .isListening {
                        HoldToReplyBubble()
                            .frame(height: 200)
                            .offset(y: -110)
                    } else if viewModel.selectedFriendIsBusy {
                        IsBusyBubble()
                            .frame(height: 200)
                            .offset(y: -110)
                    } else {
                        HoldToTalkBubble()
                            .frame(height: 200)
                            .offset(y: -110)
                    }
                }
                
                // Lock View
                if viewModel.isPressing && viewModel.isPublished && !viewModel.isLocked{
                    VStack {
                        LockViewRepresentable(isLocked: viewModel.isLocked, progress: viewModel.progress)
                    }
                    .frame(width: 100, height: 200)
                    .offset(y: -100)
                    
                    // TODO: Add rive
                    ZStack {
                        // Display the shimmer animation (background layer)
                        shimmerViewModel
                            .view()
                            .aspectRatio(66 / 88.73, contentMode: .fit) // Maintain aspect ratio
                            .frame(width: 66) // Adjust the width for shimmer effect

                        // Display the lock animation (foreground layer)
                        lockViewModel
                            .view()
                            .aspectRatio(26.43 / 31.79, contentMode: .fit) // Maintain aspect ratio
                            .frame(width: 26.43 * scale, height: 31.79 * scale) // Scale the lock icon
                            .offset(y: -15) // Move the lock slightly up
                    }
                    .padding(.bottom, 20) // Add some spacing between the animations and the long press button
                }
                
                // Scroll View
                CustomCollectionViewRepresentable(
                    selectedFriend: $viewModel.selectedFriend,
                    detailedFriends: $viewModel.detailedFriends,
                    isSheetPresented: $isSheetPresented,
                    isPressing: $viewModel.isPressing,
                    isPublished: $viewModel.isPublished,
                    isLocked: $viewModel.isLocked
                )
                .frame(height: 300)
                
                // Need to add bouncy animation when view changes
                if !viewModel.isLocked && ringAnimationState {
                    // Circle 1
                    Circle()
                        .trim(from: 0, to: 1.0) // Full circle when active
                        .stroke(.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-75)) // Shift the empty part to upper-right
                        .opacity(0.5)
                        .frame(width: strokeSize * 0.7, height: strokeSize * 0.7)
                } else if !viewModel.isLocked && !ringAnimationState {
                    // Circle 2
//                    Circle()
//                        .trim(from: 0.1, to: 1.0)  // 10% gap when inactive
//                        .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
//                        .rotationEffect(.degrees(-75)) // Shift the empty part to upper-right
//                        .opacity(1.0)
//                        .frame(width: strokeSize * 0.9, height: strokeSize * 0.9)
                    MainRingView(strokeSize: strokeSize)
                } else {
                    // Cancel Button
                    Button(action: {
                        Task {
                            viewModel.isLocked = false
                            await viewModel.unpublishAudio()
                            viewModel.disconnect()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                        }
                    }
                }
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            AnimatedBackgroundViewRepresentable(
                image: repoManager.selectedFriend.flatMap { UIImage(data: $0.profileImageData ?? Data()) },
                isPressing: $viewModel.isPressing,
                isPublished: $viewModel.isPublished
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $isSheetPresented) {
            ProfileView()
        }
        .onAppear {
            NSLog("LOG: HomeView-onAppear")
            
            // MARK: There are some cases when 'isBusy' value in firebase stays to true
            // leading no one able to call the user
            repoManager.syncIsBusy()

        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            viewModel.handleScenePhaseChange(to: newScenePhase)
        }
    }
    
    // Helper method to format the date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // or "hh:mm:ss a" for 12-hour format with AM/PM
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date)
    }
}


