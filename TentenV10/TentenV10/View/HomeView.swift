//import SwiftUI
//
//struct HomeView: View {
//    @EnvironmentObject var viewModel: ContentViewModel
//    @State private var isSheetPresented: Bool = false
//    
//    var body: some View {
//        VStack {
//            Text("Home View")
//                .padding()
//            
//            Spacer()
//            // TODO: print out friends with their username and profile image
//            Spacer()
//
//            Button(action: {
//                isSheetPresented = true
//            }) {
//                Text("Add Friend")
//                    .font(.title2)
//                    .foregroundColor(.white)
//                    .padding()
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//        }
//        .sheet(isPresented: $isSheetPresented) {
//            AddFriendView()
//        }
//    }
//}

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    @State private var isSheetPresented: Bool = false
    
    var body: some View {
        VStack {
            Text("Home View")
                .padding()
            
            Spacer()

            // Display friends with their username and profile image
            if viewModel.friendsDetails.isEmpty {
                Text("No friends available")
                    .padding()
            } else {
                ForEach(viewModel.friendsDetails, id: \.id) { friend in
                    HStack {
                        // Profile image
                        if let profileImageData = friend.profileImageData,
                           let uiImage = UIImage(data: profileImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 5)
                        } else {
                            Image(systemName: "person.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }
                        
                        // Username
                        Text(friend.username)
                            .font(.headline)
                            .padding(.leading, 10)
                        
                        Spacer()
                    }
                    .padding()
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
                .environmentObject(viewModel)
        }
    }
}
