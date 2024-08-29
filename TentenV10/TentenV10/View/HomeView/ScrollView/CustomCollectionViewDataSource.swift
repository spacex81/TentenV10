import UIKit
import SwiftUI

class CustomCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    @Binding var detailedFriends: [FriendRecord]
    @Binding var selectedFriend: FriendRecord?
    @Binding var isSheetPresented: Bool
    @Binding var isPressing: Bool
    @Binding var isLocked: Bool
    private weak var collectionViewController: CustomCollectionViewController?
    private let repoManager = RepositoryManager.shared

    init(
        detailedFriends: Binding<[FriendRecord]>,
        selectedFriend: Binding<FriendRecord?>,
        isSheetPresented: Binding<Bool>,
        isPressing: Binding<Bool>,
        isLocked: Binding<Bool>,
        collectionViewController: CustomCollectionViewController
    ) {
        self._detailedFriends = detailedFriends
        self._selectedFriend = selectedFriend
        self._isSheetPresented = isSheetPresented
        self._isPressing = isPressing
        self._isLocked = isLocked
        self.collectionViewController = collectionViewController
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return detailedFriends.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        NSLog("LOG: collectionView-cellForItemAt: \(indexPath.item)")
        let friend = detailedFriends[indexPath.item]
        
        let cell: UICollectionViewCell
        
        if indexPath.item == 0 || indexPath.item == detailedFriends.count - 1 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddButtonCell.reuseIdentifier, for: indexPath) as! AddButtonCell
            let addButtonCell = cell as! AddButtonCell
            
            addButtonCell.isPressing = isPressing
            addButtonCell.isLocked = isLocked
            addButtonCell.onTap = { [weak self] in
                self?.isSheetPresented = true // Update the binding to present the sheet
            }
            NSLog("LOG: add button is set")
        } else if friend == selectedFriend {
            NSLog("LOG: selected friend: \(friend.username)")
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: LongPressCell.reuseIdentifier, for: indexPath) as! LongPressCell
            let longPressCell = cell as! LongPressCell
            longPressCell.configure(with: friend)
            // TODO: longPressCell.friend = friend
            
            longPressCell.isPressing = isPressing
            longPressCell.isLocked = isLocked
            longPressCell.onLongPressBegan = { [weak self] in
                NSLog("LOG: onLongPressBegan")
                self?.isPressing = true
            }
            longPressCell.onLongPressEnded = { [weak self] in
                NSLog("LOG: onLongPressEnded")
                self?.isPressing = false
            }
            NSLog("LOG: long press cell is set")

        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: TapCell.reuseIdentifier, for: indexPath) as! TapCell
            let tapCell = cell as! TapCell
            tapCell.configure(with: friend)
            // TODO: tapCell.friend = friend

            tapCell.isPressing = isPressing
            tapCell.isLocked = isLocked
            tapCell.onTap = { [weak self] in
                NSLog("LOG: onTap")
                self?.collectionViewController?.centerCell(at: indexPath)
//                self?.selectedFriend = friend
                self?.repoManager.selectedFriend = friend
            }
            NSLog("LOG: tap cell is set")

        }
        
        return cell
    }
}


