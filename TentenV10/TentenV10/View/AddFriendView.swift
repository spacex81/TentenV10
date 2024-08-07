import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HomeViewModel
    
    @State private var friendPin: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Friend")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let userPin = viewModel.userRecord?.pin {
                Text("Your PIN: \(userPin)")
                    .font(.headline)
                    .padding()
            }
            
            TextField("Enter Friend's PIN", text: $friendPin)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button(action: {
                friendPin = friendPin.lowercased()
                addFriend()
            }) {
                Text("Add Friend")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.title2)
                    .foregroundColor(.blue)
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
    }
    
    private func addFriend() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else {
            NSLog("LOG: not authenticated - AddFriendView")
            return
        }
        
        viewModel.addFriendByPin(currentUserId: uid, friendPin: friendPin) { result in
            switch result {
            case .success(let friendId):
                NSLog("Friend added with ID: \(friendId)")
                dismiss()
            case .failure(let error):
                NSLog("Failed to add friend: \(error.localizedDescription)")
            }
        }
    }
}

