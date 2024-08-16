import UIKit
import SwiftUI

class CustomCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    @Binding var detailedFriends: [FriendRecord]
    @Binding var selectedFriend: FriendRecord?
    private weak var collectionViewController: CustomCollectionViewController?


    init(detailedFriends: Binding<[FriendRecord]>, selectedFriend: Binding<FriendRecord?>, collectionViewController: CustomCollectionViewController) {
        self._detailedFriends = detailedFriends
        self._selectedFriend = selectedFriend
        self.collectionViewController = collectionViewController
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return detailedFriends.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
        let friend = detailedFriends[indexPath.item]
        cell.friend = friend
        cell.onTap = { [weak self] in
            self?.collectionViewController?.centerCell(at: indexPath)
        }
        cell.configure(with: friend)
        return cell
    }
}
