import UIKit
import SwiftUI

class CustomCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    @Binding var detailedFriends: [FriendRecord]
    @Binding var selectedFriend: FriendRecord?
    @Binding var isSheetPresented: Bool
    @Binding var isPressing: Bool
    private weak var collectionViewController: CustomCollectionViewController?

    init(
        detailedFriends: Binding<[FriendRecord]>,
        selectedFriend: Binding<FriendRecord?>,
        isSheetPresented: Binding<Bool>,
        isPressing: Binding<Bool>,
        collectionViewController: CustomCollectionViewController
    ) {
        self._detailedFriends = detailedFriends
        self._selectedFriend = selectedFriend
        self._isSheetPresented = isSheetPresented
        self._isPressing = isPressing
        self.collectionViewController = collectionViewController
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return detailedFriends.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 || indexPath.item == detailedFriends.count - 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddButtonCell.reuseIdentifier, for: indexPath) as! AddButtonCell
            cell.onTap = { [weak self] in
                self?.isSheetPresented = true // Update the binding to present the sheet
            }
            cell.isPressing = isPressing
            return cell
        } else {
            let friend = detailedFriends[indexPath.item]
            if friend == selectedFriend {
                NSLog("LOG: selected friend: \(friend.username)")
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LongPressCell.reuseIdentifier, for: indexPath) as! LongPressCell
                cell.configure(with: friend)
                
                cell.onLongPressBegan = { [weak self] in
                    NSLog("LOG: onLongPressBegan")
                    self?.isPressing = true
                }
                cell.onLongPressEnded = { [weak self] in
                    NSLog("LOG: onLongPressEnded")
                    self?.isPressing = false
                }
                
                cell.isPressing = isPressing
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TapCell.reuseIdentifier, for: indexPath) as! TapCell
                cell.configure(with: friend)
                
                cell.onTap = { [weak self] in
                    NSLog("LOG: onTap")
                    self?.collectionViewController?.centerCell(at: indexPath)
                    self?.selectedFriend = friend
                }
                
                cell.isPressing = isPressing
                return cell
            }
        }
    }
}


