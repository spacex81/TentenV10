import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared
    
    var body: some View {
        VStack {
            if let selectedFriend = viewModel.selectedFriend {
                VStack {
                    if let imageData = selectedFriend.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                        
                        Text(selectedFriend.username)
                            .font(.title)
                            .padding(.top, 10)
                    }
                }
                .padding(.bottom, 20)
            } else {
                VStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                        .foregroundColor(.gray)
                    
                    Text("No Friend Selected")
                        .font(.title)
                        .padding(.top, 10)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 20)
            }
            
            // UIKit Scroll View
            CustomCollectionViewRepresentable(selectedFriend: $viewModel.selectedFriend, detailedFriends: $viewModel.detailedFriends)
                .frame(height: 300)
            
            // Press-Hold-to-Talk Button
            PressHoldToTalkButton(viewModel: viewModel)
                .padding(.bottom, 20)
            
            Button(action: {
                isSheetPresented = true
            }) {
                Text("Add Friend")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            viewModel.handleScenePhaseChange(to: newScenePhase)
        }
    }
}
