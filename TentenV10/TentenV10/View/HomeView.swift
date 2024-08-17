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
                CustomCollectionViewRepresentable(selectedFriend: $viewModel.selectedFriend, detailedFriends: $viewModel.detailedFriends, isSheetPresented: $isSheetPresented)
                    .frame(height: 300)
                
                Circle()
                    .stroke(.white, lineWidth: 10)
                    .frame(width: strokeSize, height: strokeSize)
                // TODO: set the strokeSize as the 110% of the itemSize of the collection view item
                
//                let standardItemSpacing: CGFloat = 10
//                let screenWidth = collectionView!.bounds.width
//                let totalSpacing = standardItemSpacing * 2 // 2 gaps of 10 points each
//                let itemWidth = (screenWidth - totalSpacing) / 3.0
//
//                itemSize = CGSize(width: itemWidth, height: itemWidth)
                
                
                // 'collectionView!.bounds.width' this value is same with screen width so it is possible to calculate the stroke size
            }
            
            // Press-Hold-to-Talk Button
            PressHoldToTalkButton(viewModel: viewModel)
                .padding(.bottom, 20)
            
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

