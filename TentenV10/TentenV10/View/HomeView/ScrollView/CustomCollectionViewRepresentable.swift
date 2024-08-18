import SwiftUI

struct CustomCollectionViewRepresentable: UIViewRepresentable {
    @Binding var selectedFriend: FriendRecord?
    @Binding var detailedFriends: [FriendRecord]
    @Binding var isSheetPresented: Bool
    @Binding var isPressing: Bool

    func makeUIView(context: Context) -> UIView {
        let container = CustomCollectionViewContainer(
            selectedFriend: $selectedFriend,
            detailedFriends: $detailedFriends,
            isSheetPresented: $isSheetPresented,
            isPressing: $isPressing
        )
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let container = uiView as? CustomCollectionViewContainer {
            container.updateDetailedFriends(detailedFriends)
        }
    }
}
