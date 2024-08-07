import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var profileImage: UIImage? = nil
    @State private var isSheetPresented: Bool = false
    
    var body: some View {
        VStack {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .padding()
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 150, height: 150)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .padding()
            }
            
            if let userRecord = viewModel.userRecord {
                Text("Email: \(userRecord.email)")
                    .padding()
                
                Text("Token: \(String(describing: userRecord.deviceToken))")
                    .padding()
                
                Text("Pin: \(userRecord.pin)")
                    .padding()
                Text("Username: \(userRecord.username)")
                Text("hasIncomingCallRequest: \(userRecord.hasIncomingCallRequest ? "True" : "False")")
                
                // Display list of friend IDs
                if !userRecord.friends.isEmpty {
                    Text("Friends:")
                        .font(.headline)
                        .padding(.top)
                    
                    List(userRecord.friends, id: \.self) { friendId in
                        Text("Friend ID: \(friendId)")
                    }
                    .frame(height: 200) // Adjust height as needed
                } else {
                    Text("No friends added yet.")
                        .padding()
                }
            } else {
                Text("Loading user information...")
                    .padding()
            }
            
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
        .padding()
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView(viewModel: viewModel)
        }
        .onAppear {
            NSLog("LOG: onAppear")
            refreshUserRecord()
        }
        .onChange(of: viewModel.userRecord) { _, _ in
            NSLog("LOG: onChange")
            updateProfileImage()
        }
        .onChange(of: viewModel.userRecord?.friends) { _, _ in
            NSLog("LOG: friends changed")
            refreshUserRecord()
        }
    }
    
    private func refreshUserRecord() {
        NSLog("LOG: refreshUserRecord")
        guard let currentUser = Auth.auth().currentUser else { return }
        viewModel.fetchUserFromDatabase(currentUserId: currentUser.uid)
        updateProfileImage()
    }

    private func updateProfileImage() {
        if let userRecord = viewModel.userRecord, let imageData = userRecord.profileImageData {
            profileImage = UIImage(data: imageData)
        } else {
            profileImage = nil
        }
    }
}

