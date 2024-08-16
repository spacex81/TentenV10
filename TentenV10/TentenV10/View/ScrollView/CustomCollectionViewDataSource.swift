import UIKit
import SwiftUI

class CustomCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    @Binding var detailedFriends: [FriendRecord]
    @Binding var selectedFriend: FriendRecord?

    init(detailedFriends: Binding<[FriendRecord]>, selectedFriend: Binding<FriendRecord?>) {
        self._detailedFriends = detailedFriends
        self._selectedFriend = selectedFriend
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return detailedFriends.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
        let friend = detailedFriends[indexPath.item]
        cell.configure(with: friend)
        return cell
    }
}
