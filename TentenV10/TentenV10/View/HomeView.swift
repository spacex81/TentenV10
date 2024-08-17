//import SwiftUI
//
//struct HomeView: View {
//    @Environment(\.scenePhase) private var scenePhase
//    @State private var isSheetPresented: Bool = false
//    @ObservedObject var viewModel = HomeViewModel.shared
//    
//    var body: some View {
//        VStack {
//            if let selectedFriend = viewModel.selectedFriend {
//                Text(selectedFriend.username)
//                    .font(.title)
//                    .padding(.top, 10)
//            } else {
//                Text("No Friend Selected")
//                    .font(.title)
//                    .padding(.top, 10)
//                    .foregroundColor(.gray)
//            }
//            
//            // UIKit Scroll View
//            CustomCollectionViewRepresentable(selectedFriend: $viewModel.selectedFriend, detailedFriends: $viewModel.detailedFriends)
//                .frame(height: 300)
//            
//            // Press-Hold-to-Talk Button
//            PressHoldToTalkButton(viewModel: viewModel)
//                .padding(.bottom, 20)
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
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(
//            Group {
//                if let imageData = viewModel.selectedFriend?.profileImageData, let uiImage = UIImage(data: imageData) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFill()
//                        .ignoresSafeArea()
//                } else {
//                    Color.clear
//                        .ignoresSafeArea()
//                }
//            }
//        )
//        .sheet(isPresented: $isSheetPresented) {
//            AddFriendView()
//        }
//        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
//            viewModel.handleScenePhaseChange(to: newScenePhase)
//        }
//    }
//}
//

import SwiftUI

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared
    
    var body: some View {
        VStack {
            if let selectedFriend = viewModel.selectedFriend {
                Text(selectedFriend.username)
                    .font(.title)
                    .padding(.top, 10)
            } else {
                Text("No Friend Selected")
                    .font(.title)
                    .padding(.top, 10)
                    .foregroundColor(.gray)
            }
            
            // UIKit Scroll View
            CustomCollectionViewRepresentable(selectedFriend: $viewModel.selectedFriend, detailedFriends: $viewModel.detailedFriends, isSheetPresented: $isSheetPresented)
                .frame(height: 300)
            
            // Press-Hold-to-Talk Button
            PressHoldToTalkButton(viewModel: viewModel)
                .padding(.bottom, 20)
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if let imageData = viewModel.selectedFriend?.profileImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                } else {
                    Color.clear
                        .ignoresSafeArea()
                }
            }
        )
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            viewModel.handleScenePhaseChange(to: newScenePhase)
        }
    }
}

