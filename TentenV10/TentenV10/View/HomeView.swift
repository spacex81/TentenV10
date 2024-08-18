import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared
    
    
    // size of the collection view item
    var itemSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let standardItemSpacing: CGFloat = 10
        let totalSpacing = standardItemSpacing * 2 // 2 gaps of 10 points each
        return (screenWidth - totalSpacing) / 3.0
    }
    
    var strokeSize: CGFloat {
        return itemSize * 1.05
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            if let selectedFriend = viewModel.selectedFriend {
                Text(selectedFriend.username)
                    .font(.title)
                    .padding(.top, 10)
            } else {
                Text("No Friend Selected")
                    .font(.title)
                    .padding(.top, 10)
                    .foregroundColor(.gray)
            }
            
            ZStack {
                // Scroll View
                CustomCollectionViewRepresentable(selectedFriend: $viewModel.selectedFriend, detailedFriends: $viewModel.detailedFriends, isSheetPresented: $isSheetPresented, isPressing: $viewModel.isPressing)
                    .frame(height: 300)
                
                // Ring
                Circle()
                    .trim(from: viewModel.isPressing ? 0 : 0.1, to: 1.0) // 0.125 is approximately 1.5/12
                    .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-75)) // Start from top
                    .opacity(viewModel.isPressing ? 0.5 : 1.0)
                    .frame(width: viewModel.isPressing ? strokeSize * 0.7 : strokeSize, height: viewModel.isPressing ? strokeSize * 0.7 : strokeSize)
                    .animation(.easeInOut(duration: 0.1), value: viewModel.isPressing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if let imageData = viewModel.selectedFriend?.profileImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    Color.clear
                        .ignoresSafeArea()
                }
            }
        )
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            viewModel.handleScenePhaseChange(to: newScenePhase)
        }
    }
}


