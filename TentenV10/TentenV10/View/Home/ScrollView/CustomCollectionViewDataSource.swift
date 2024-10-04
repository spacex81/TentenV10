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
    private let liveKitManager = LiveKitManager.shared

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
//        NSLog("LOG: Number of items in section: \(detailedFriends.count)")
        return detailedFriends.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        NSLog("LOG: collectionView-cellForItemAt: \(indexPath.item)")
        NSLog("LOG: currentState: \(repoManager.currentState)")
        NSLog("LOG: detailedFriends count: \(detailedFriends.count)")
        
        let friend = detailedFriends[indexPath.item]
        if selectedFriend != nil {
            NSLog("LOG: selectedFriend")
            print(selectedFriend ?? "not selected yet")
            NSLog("LOG: friend")
            print(friend)
        }
        
        let cell: UICollectionViewCell
        
        if indexPath.item == 0 || indexPath.item == detailedFriends.count - 1 {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddButtonCell.reuseIdentifier, for: indexPath) as! AddButtonCell
            let addButtonCell = cell as! AddButtonCell
            
            addButtonCell.isPressing = isPressing
            addButtonCell.isLocked = isLocked
            if repoManager.currentState == .isListening {
                addButtonCell.shrinkWhenListening = true
            } else {
                addButtonCell.shrinkWhenListening = false
            }
            addButtonCell.onTap = { [weak self] in
                self?.isSheetPresented = true // Update the binding to present the sheet
            }
            NSLog("LOG: add button is set for \(friend.username)")
        } else if friend.id == selectedFriend?.id {
//        } else if friend.id == self.repoManager.selectedFriend?.id {
//            NSLog("LOG: selected friend: \(friend.username)")
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: LongPressCell.reuseIdentifier, for: indexPath) as! LongPressCell
            let longPressCell = cell as! LongPressCell
            longPressCell.configure(with: friend)
            
            longPressCell.isPressing = isPressing
            longPressCell.isLocked = isLocked
            
            // Control long press recognizer
            if friend.isBusy && repoManager.currentState == .idle && !liveKitManager.isConnected && !isPressing {
                NSLog("LOG: long press gesture disabeld")
                longPressCell.longPressGestureRecognizer.isEnabled = false
            } else if longPressCell.longPressGestureRecognizer.isEnabled == false {
                NSLog("LOG: long press gesture enabled")
                longPressCell.longPressGestureRecognizer.isEnabled = true
            }
            
            longPressCell.onLongPressBegan = { [weak self] in
                NSLog("LOG: onLongPressBegan")
                self?.isPressing = true
            }
            longPressCell.onLongPressEnded = { [weak self] in
                NSLog("LOG: onLongPressEnded")
                self?.isPressing = false
            }
            NSLog("LOG: long press cell is set for \(friend.username)")

        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: TapCell.reuseIdentifier, for: indexPath) as! TapCell
            let tapCell = cell as! TapCell
            tapCell.configure(with: friend)

            tapCell.isPressing = isPressing
            tapCell.isLocked = isLocked
            if repoManager.currentState == .isListening {
                tapCell.shrinkWhenListening = true
            } else {
                tapCell.shrinkWhenListening = false
            }
            
            tapCell.onTap = { [weak self] in
//                NSLog("LOG: onTap")
                self?.collectionViewController?.centerCell(at: indexPath)
                self?.repoManager.selectedFriend = friend
            }
            NSLog("LOG: tap cell is set for \(friend.username)")

            /**
             DO NOT ERASE:
             there are some occasion when centered cell is set as tap cell
             in those cases we need to programmatically press the tap cell and
             turn it into long press cell
             */
//            if friend.id == selectedFriend?.id {
//                self.repoManager.selectedFriend = friend
//            }
        }
        
        return cell
    }
}


