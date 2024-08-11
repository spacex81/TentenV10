//
//  AddFriendView.swift
//  TentenV10
//
//  Created by 조윤근 on 8/8/24.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack {
            Text("Add Friend")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let userPin = viewModel.userRecord?.pin {
                Text("Your PIN: \(userPin)")
                    .font(.headline)
                    .padding()
            }
            
            TextField("Enter Friend's PIN", text: $viewModel.friendPin)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.friendPin = viewModel.friendPin.lowercased()
                viewModel.addFriend()
                dismiss()
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
            if let userRecord = viewModel.userRecord, let imageData = userRecord.profileImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(radius: 10)
                
                Text(userRecord.username)
                    .font(.title)
                    .padding(.top, 10)
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
}

#Preview {
    AddFriendView()
}
