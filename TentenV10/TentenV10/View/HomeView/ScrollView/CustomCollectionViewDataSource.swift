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
        let friend = detailedFriends[indexPath.item]
        
        let cell: UICollectionViewCell
        
        if indexPath.item == 0 || indexPath.item == detailedFriends.count - 1 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddButtonCell.reuseIdentifier, for: indexPath) as! AddButtonCell
            (cell as! AddButtonCell).onTap = { [weak self] in
                self?.isSheetPresented = true // Update the binding to present the sheet
            }
        } else if friend == selectedFriend {
            NSLog("LOG: selected friend: \(friend.username)")
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: LongPressCell.reuseIdentifier, for: indexPath) as! LongPressCell
            let longPressCell = cell as! LongPressCell
            longPressCell.configure(with: friend)
            
            longPressCell.onLongPressBegan = { [weak self] in
                NSLog("LOG: onLongPressBegan")
                self?.isPressing = true
            }
            longPressCell.onLongPressEnded = { [weak self] in
                NSLog("LOG: onLongPressEnded")
                self?.isPressing = false
            }
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: TapCell.reuseIdentifier, for: indexPath) as! TapCell
            let tapCell = cell as! TapCell
            tapCell.configure(with: friend)
            
            tapCell.onTap = { [weak self] in
                NSLog("LOG: onTap")
                self?.collectionViewController?.centerCell(at: indexPath)
                self?.selectedFriend = friend
            }
        }
        
        // Ensure the cell is updated correctly
        animateScale(isPressing: isPressing, cell: cell)
        
        return cell
    }

    func animateScale(isPressing: Bool, cell: UICollectionViewCell) {
        let scaleTransform = isPressing ? CGAffineTransform(scaleX: 0.001, y: 0.001) : .identity
        
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.6, // Adjust damping for bounce effect
            initialSpringVelocity: 0.8,  // Adjust velocity for bounce intensity
            options: [],
            animations: {
                cell.transform = scaleTransform
            },
            completion: nil
        )
    }
}


