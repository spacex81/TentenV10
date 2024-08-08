//
//  HomeView.swift
//  TentenV10
//
//  Created by 조윤근 on 8/8/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @State private var isSheetPresented: Bool = false
    
    var body: some View {
        VStack {
            Text("Home View")
            Spacer()
            if let userRecord = viewModel.userRecord {
                Text(userRecord.username)
                    .padding()
                Text(userRecord.pin)
                    .padding()
                Text(userRecord.deviceToken ?? "Empty Device Token")
                    .padding()
                
                // Profile Image
                if let imageData = userRecord.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding()
                } else {
                    Text("No Profile Image")
                        .padding()
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
            if viewModel.currentUserId != nil {
                NSLog("LOG: fetch user record on appear")
                viewModel.fetchUser()
            }
        }
    }
}

#Preview {
    HomeView()
}
