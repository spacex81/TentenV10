import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared

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
                if let selectedFriend = viewModel.selectedFriend {
                    if viewModel.isPressing && !viewModel.isPublished {
                        ShimmeringViewControllerRepresentable(text: "Connecting", font: UIFont.boldSystemFont(ofSize: 24), fontSize: 24)
                            .frame(width: 200, height: 30)
                            .transition(.opacity)
                    } else if viewModel.isPressing && viewModel.isPublished && !viewModel.isLocked {
                        ShimmeringViewControllerRepresentable(text: "Slide up to lock", font: UIFont.boldSystemFont(ofSize: 24), fontSize: 24)

                            .frame(width: 200, height: 30)
                            .transition(.opacity)
                    } else {
                        Text(selectedFriend.username)
                            .font(.system(size: 24, weight: .bold, design: .default))
                            .font(.title)
                            .padding(.top, 10)
                            .transition(.opacity)
                    }
                }
            }

            ZStack {
                // Speech bubble
                if !viewModel.isPressing && !viewModel.isLocked {
                    if !viewModel.isConnected {
                        if viewModel.selectedFriendIsBusy {
                            IsBusyBubble()
                                .frame(height: 200)
                                .offset(y: -110)
                        } else {
                            HoldToTalkBubble()
                               .frame(height: 200)
                               .offset(y: -110)
                        }

                    } else {
                        HoldToReplyBubble()
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
                        Circle()
                            .trim(from: 0.1, to: 1.0) // 10% gap when inactive
                            .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-75)) // Shift the empty part to upper-right
                            .opacity(1.0)
                            .frame(width: strokeSize, height: strokeSize)
                } else {
                        // Cancel Button
                    Button(action: {
                        Task {
                            viewModel.isLocked = false
                            // TODO: current user's isBusy value to false 
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
                image: viewModel.selectedFriend.flatMap { UIImage(data: $0.profileImageData ?? Data()) },
                isPressing: $viewModel.isPressing,
                isPublished: $viewModel.isPublished
            )
            .ignoresSafeArea()
        )
        .sheet(isPresented: $isSheetPresented) {
            ProfileView()
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            viewModel.handleScenePhaseChange(to: newScenePhase)
        }
    }
}


