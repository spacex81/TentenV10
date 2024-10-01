import SwiftUI

struct ProfileView: View {
    @State private var isSheetPresented: Bool = false
//   @ObservedObject var viewModel = HomeViewModel.shared // Case 1
    // This view model is not updated on realtime
    let viewModel = HomeViewModel.shared // Case 2
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)


    var body: some View {
        VStack {
            if let userRecord = viewModel.userRecord, let imageData = userRecord.profileImageData, let uiImage = UIImage(data: imageData) {
                
                // user profile panel
                HStack {
                    // username and pin
                    VStack(alignment: .leading) {
                        Text(userRecord.username)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 1)
                        if let userPin = viewModel.userRecord?.pin {
                            PinButton(pin: userPin)
                        }
                    }
                    Spacer()
                    // profile pic
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .shadow(radius: 10)
                }
                .padding(10)
                
                // add friends button
                Button {
                    isSheetPresented = true
                    impactFeedback.impactOccurred()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .tint(.white)
                            .fontWeight(.bold)
                            .font(.title2)
                        Text("add friends")
                            .tint(.white)
                            .fontWeight(.bold)
                            .font(.title2)
                        Spacer()
                    }
                    .padding(25)
                    .background(Color(UIColor(white: 0.3, alpha: 1.0)))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                
                // Friends List with Three-dot Button
                ScrollView {
                    VStack {
                        ForEach(viewModel.detailedFriends, id: \.id) { friend in
                            HStack {
                                // Friend's profile pic and name
                                HStack {
                                    if let friendImageData = friend.profileImageData, let friendImage = UIImage(data: friendImageData) {
                                        Image(uiImage: friendImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(Circle())
                                            .shadow(radius: 5)
                                    }
                                    Text(friend.username)
                                        .font(.headline)
                                        .padding(.leading, 10)
                                }
                                Spacer()
                                
                                // Three-dot menu button
                                Button(action: {
                                    // TODO: Implement action for the menu
                                    print("Three dot menu tapped for \(friend.username)")
                                }) {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(Color.gray)
                                        .padding(.trailing, 10)
                                }
                            }
                            .padding()
                        }
                    }
                }
                .background(Color.clear)
                //                Spacer()
            }
            
//            Button(action: {
//                viewModel.signOut()
//            }) {
//                Text("Sign Out")
//                    .font(.title2)
//                    .foregroundColor(.red)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                    .cornerRadius(10)
//                    .padding(.horizontal)
//            }
        }
        .padding(30)
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .frame(maxWidth: .infinity)
    }
}

var dummyUserRecord: UserRecord {
    let image = UIImage(named: "user1")!  // Use system image for preview
    let imageData = image.pngData()
    return UserRecord(
        id: UUID().uuidString,
        email: "john.doe@example.com",
        username: "John Doe",
        password: "dummyPassword123",
        pin: "123456",
        hasIncomingCallRequest: false,
        profileImageData: imageData,
        deviceToken: nil,
        friends: ["friend1", "friend2"],
        roomName: "testRoom",
        isBusy: false,
        socialLoginId: "dummySocialLoginId",
        socialLoginType: "facebook",
        imageOffset: 0.0
    )
}

var dummyFriends: [FriendRecord] {
    return [
        FriendRecord(
            id: UUID().uuidString,
            email: "friend1@example.com",
            username: "Friend 1",
            pin: "111111",
            profileImageData: UIImage(named: "user2")?.pngData(), // Image from Assets
            deviceToken: nil,
            userId: "userId1",
            isBusy: false,
            lastInteraction: Date()
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "friend2@example.com",
            username: "Friend 2",
            pin: "222222",
            profileImageData: UIImage(named: "user3")?.pngData(), // Image from Assets
            deviceToken: nil,
            userId: "userId2",
            isBusy: false,
            lastInteraction: Date()
        ),
        // Add more friends with images from "user4" to "user10"
        FriendRecord(
            id: UUID().uuidString,
            email: "friend3@example.com",
            username: "Friend 3",
            pin: "333333",
            profileImageData: UIImage(named: "user4")?.pngData(),
            deviceToken: nil,
            userId: "userId3",
            isBusy: false,
            lastInteraction: Date()
        )
    ]
}

#Preview {
    HomeViewModel.shared.userRecord = dummyUserRecord
    HomeViewModel.shared.detailedFriends = dummyFriends
    
    return ProfileView()
        .preferredColorScheme(.dark)
}
