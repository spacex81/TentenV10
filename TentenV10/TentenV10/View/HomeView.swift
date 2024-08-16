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

struct PressHoldToTalkButton: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isPressed ? Color.red : Color.green)
                .frame(width: 100, height: 100)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)

            Text(isPressed ? "Talking..." : "Hold to Talk")
                .foregroundColor(.white)
                .font(.headline)
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { isPressing in
            isPressed = isPressing
            if isPressing {
                // Start talking: connect and publish
                Task {
                    if !viewModel.isConnected {
                        await viewModel.connect()
                    }
                    viewModel.publishAudio()
                }
            } else {
                // Stop talking: unpublish
                Task {
                    await viewModel.unpublishAudio()
                    viewModel.disconnect()
                }
            }
        }) {
            // Optional: action to perform when the gesture ends
            print("Talk ended")
        }
    }
}
