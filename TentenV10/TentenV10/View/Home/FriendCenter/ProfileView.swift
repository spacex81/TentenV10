import SwiftUI

struct ProfileView: View {
    @State private var isAddFriendSheetPresented: Bool = false
    @State private var friendToDelete: FriendRecord?
    
    // State for showing delete view as an overlay
    @State private var showDeleteBottomSheet = false
    @State private var showImageBottomSheet = false

    // MARK: Use this for preview
//    let viewModel = HomeViewModel.shared
    // MARK: Use this for real app
    @ObservedObject var viewModel = HomeViewModel.shared

    var body: some View {
        ZStack {
            VStack {
                if let userRecord = viewModel.userRecord, let imageData = userRecord.profileImageData, let uiImage = UIImage(data: imageData) {

                    // User profile panel
                    HStack {
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
                        
                        // TODO: Add 'change profile picture'
                        // Make this image view clickable
                        // Show profile image update bottom sheet 
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                            .onTapGesture {
                                withAnimation {
                                    showImageBottomSheet = true
                                }
                            }
                    }
                    .padding(10)

                    // Add friends button
                    Button {
                        isAddFriendSheetPresented = true
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

                                    Button(action: {
                                        withAnimation {
                                            friendToDelete = friend
                                            showDeleteBottomSheet = true
                                        }
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
                }
            }
            .padding(30)
            .sheet(isPresented: $isAddFriendSheetPresented) {
                AddFriendView()
            }
            .background(DeleteBottomSheetViewControllerRepresentable(isPresented: $showDeleteBottomSheet, friendToDelete: $friendToDelete))
            .background(ImageBottomSheetViewControllerRepresentable(isPresented: $showImageBottomSheet))
        }
    }
}

#Preview {
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

    let dummyFriend = FriendRecord(
        id: UUID().uuidString,
        email: "friend1@example.com",
        username: "Dummy Friend",
        pin: "111111",
        profileImageData: UIImage(named: "user2")?.pngData(),
        deviceToken: nil,
        userId: "userId1",
        isBusy: false,
        lastInteraction: Date()
    )

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
    
    HomeViewModel.shared.userRecord = dummyUserRecord
    HomeViewModel.shared.detailedFriends = dummyFriends

    return ProfileView()
        .preferredColorScheme(.dark)
}
