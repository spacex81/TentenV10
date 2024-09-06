import SwiftUI

struct HomeViewPreview: View {
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
                            .font(.title)
                            .padding(.top, 10)
                            .transition(.opacity)
                        
                        Text("hold to talk")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .padding(.horizontal)
                            .background(
                                SpeechBubbleShapeDownward()
                                    .fill(Color(.white))
                                    .offset(y: -5)
                            )
                    }
                }
            }
            .border(.green)


            ZStack {
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
        .onAppear {
            loadTestData() // Load test data for preview
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            viewModel.handleScenePhaseChange(to: newScenePhase)
        }
    }
}

extension HomeViewPreview {
    private func loadTestData() {
        viewModel.detailedFriends = [
            FriendRecord(
                id: "1",
                email: "friend1@example.com",
                username: "Friend One",
                pin: "1234",
                profileImageData: UIImage(systemName: "person.fill")?.pngData(),
                deviceToken: "token1",
                userId: "user1",
                isBusy: false
            ),
            FriendRecord(
                id: "2",
                email: "friend2@example.com",
                username: "Friend Two",
                pin: "5678",
                profileImageData: UIImage(systemName: "person.fill")?.pngData(),
                deviceToken: "token2",
                userId: "user2",
                isBusy: true
            ),
            FriendRecord(
                id: "3",
                email: "friend3@example.com",
                username: "Friend Three",
                pin: "9012",
                profileImageData: UIImage(systemName: "person.fill")?.pngData(),
                deviceToken: "token3",
                userId: "user3",
                isBusy: false
            )
        ]
        
        // Set a default selected friend for the preview
        viewModel.selectedFriend = viewModel.detailedFriends.first
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
