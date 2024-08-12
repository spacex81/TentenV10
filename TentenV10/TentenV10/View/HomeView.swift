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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(viewModel.detailedFriends, id: \.id) { friend in
                        VStack {
                            if let imageData = friend.profileImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .shadow(radius: 10)
                                    .onTapGesture {
                                        viewModel.selectFriend(friend: friend)
                                    }
                                    .opacity(friend.isBusy ? 0.5 : 1.0)
                            }
                            
                            Text(friend.username)
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
            
            Text(viewModel.isConnected ? "Connected" : "Tap to Connect")
                .foregroundColor(viewModel.selectedFriend == nil ? .gray : .blue)
                .onTapGesture {
                    guard viewModel.selectedFriend != nil else {return}
                    if !viewModel.isConnected {
                        Task {
                            await viewModel.connect()
                        }
                    } else {
                        viewModel.disconnect()
                    }
                }
                .padding(.bottom, 20)
            
            Text(viewModel.isPublished ? "Published" : "Tap to Publish")
                .foregroundColor(viewModel.selectedFriend == nil ? .gray : .blue)
                .onTapGesture {
                    guard viewModel.selectedFriend != nil else {return}
                    if !viewModel.isPublished {
                        viewModel.publishAudio()
                    } else {
                        Task {
                            await viewModel.unpublishAudio()
                        }
                    }
                }
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
