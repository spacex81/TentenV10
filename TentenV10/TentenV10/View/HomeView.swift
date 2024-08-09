import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @State private var isSheetPresented: Bool = false

    var body: some View {
        VStack {
            if let userRecord = viewModel.userRecord {
                Text(userRecord.username)
                Text(userRecord.deviceToken ?? "Empty Device Token")
                if let imageData = userRecord.profileImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 5)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 50, height: 50)
                }
                
                if userRecord.friends.isEmpty {
                    Text("No FriendIds")
                        .padding()
                } else {
                    List(userRecord.friends, id: \.self) { friendId in
                        Text(friendId)
                    }
                }
                
                if viewModel.detailedFriends.isEmpty {
                    Text("No Friends")
                        .padding()
                } else {
                    List(viewModel.detailedFriends, id: \.id) { friend in
                        HStack {
                            if let imageData = friend.profileImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 5)
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 50, height: 50)
                            }
                            VStack(alignment: .leading) {
                                Text(friend.username)
                                    .font(.headline)
                                Text(friend.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 200) // Adjust height as needed
                }
            }
            // Add FriendView
            Spacer()

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
        .onAppear {
            NSLog("LOG: onAppear")
            if viewModel.needUserFetch, let id = viewModel.currentUser?.uid {
                NSLog("LOG: fetch user record on appear")
                Task {
                    try await viewModel.fetchUser(id: id)
                }
            }
            
//            if !viewModel.isListeningToFriends {
//                // listen to friends
//                viewModel.listenToFriends()
//            }
        }
    }
}

#Preview {
    HomeView()
}
