import SwiftUI

struct CustomCollectionView: UIViewControllerRepresentable {
    @Binding var selectedFriend: FriendRecord?
    @Binding var detailedFriends: [FriendRecord]

    func makeUIViewController(context: Context) -> CustomCollectionViewController {
        return CustomCollectionViewController(selectedFriend: $selectedFriend, detailedFriends: $detailedFriends)
    }

    // reload when 'detailedFriends' is fetched from firebase
    func updateUIViewController(_ uiViewController: CustomCollectionViewController, context: Context) {
        uiViewController.collectionView.reloadData()
    }
}
