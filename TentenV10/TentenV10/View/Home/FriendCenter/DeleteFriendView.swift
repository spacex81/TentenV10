import SwiftUI

struct DeleteFriendView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var friend: FriendRecord?  // Binding the friend to ProfileView
    
    var body: some View {
        VStack {
            if let friend = friend {
                Text(friend.username)
                Spacer()

                Button {
                    // Handle delete logic here
                    self.friend = nil
                    dismiss()
                } label: {
                    Text("delete friend")
                }
                Spacer()

                Button {
                    self.friend = nil
                    dismiss()
                } label: {
                    Text("close")
                }
                Spacer()
            }
        }
    }
}

#Preview {
    let dummyFriend = FriendRecord(
        id: UUID().uuidString,
        email: "friend1@example.com",
        username: "Friend 1",
        pin: "111111",
        profileImageData: UIImage(named: "user2")?.pngData(),
        deviceToken: nil,
        userId: "userId1",
        isBusy: false,
        lastInteraction: Date()
    )
    
    DeleteFriendView(friend: .constant(dummyFriend))
        .preferredColorScheme(.dark)
}
