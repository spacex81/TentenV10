import SwiftUI

struct InvitationsCenter: View {
    @ObservedObject var contentViewModel = ContentViewModel.shared

    var body: some View {
        VStack(alignment: .center) {
            Text("보낸 초대장")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)
                .padding(.leading)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(contentViewModel.sentInvitations) { invitation in
                        HStack {
                            // Friend's profile picture
                            if let profileImage = UIImage(data: invitation.profileImageData) {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
//                                    .shadow(radius: 5)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                            }

                            // Friend's username
                            Text(invitation.username)
                                .font(.headline)
                                .padding(.leading, 10)

                            Spacer() // Aligns the username to the left

                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color.clear)
        }
        .padding(.top)
    }
}

#Preview {
    InvitationsCenter()
}
