//import SwiftUI
//
//struct CustomCollectionViewRepresentable: UIViewRepresentable {
//    @Binding var selectedFriend: FriendRecord?
//    @Binding var detailedFriends: [FriendRecord]
//
//    func makeUIView(context: Context) -> UIView {
//        let container = CustomCollectionViewContainer(selectedFriend: $selectedFriend, detailedFriends: $detailedFriends)
//        return container
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {
//        if let container = uiView as? CustomCollectionViewContainer {
//            container.updateDetailedFriends(detailedFriends)
//        }
//    }
//}

import SwiftUI

struct CustomCollectionViewRepresentable: UIViewRepresentable {
    @Binding var selectedFriend: FriendRecord?
    @Binding var detailedFriends: [FriendRecord]
    @Binding var isSheetPresented: Bool

    func makeUIView(context: Context) -> UIView {
        let container = CustomCollectionViewContainer(selectedFriend: $selectedFriend, detailedFriends: $detailedFriends, isSheetPresented: $isSheetPresented)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let container = uiView as? CustomCollectionViewContainer {
            container.updateDetailedFriends(detailedFriends)
        }
    }
}
