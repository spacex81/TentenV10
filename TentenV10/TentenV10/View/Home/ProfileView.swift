import SwiftUI

struct ProfileView: View {
    @State private var isSheetPresented: Bool = false
//   @ObservedObject var viewModel = HomeViewModel.shared
    let viewModel = HomeViewModel.shared
    
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
                
                Spacer()

            }
            
            Button(action: {
                viewModel.signOut()
            }) {
                Text("Sign Out")
                    .font(.title2)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
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

#Preview {
    HomeViewModel.shared.userRecord = dummyUserRecord
    
    return ProfileView()
        .preferredColorScheme(.dark)
}
