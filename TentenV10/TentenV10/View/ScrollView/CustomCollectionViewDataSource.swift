//import UIKit
//import SwiftUI
//
//class CustomCollectionViewDataSource: NSObject, UICollectionViewDataSource {
//    @Binding var detailedFriends: [FriendRecord]
//    @Binding var selectedFriend: FriendRecord?
//    private weak var collectionViewController: CustomCollectionViewController?
//
//
//    init(detailedFriends: Binding<[FriendRecord]>, selectedFriend: Binding<FriendRecord?>, collectionViewController: CustomCollectionViewController) {
//        self._detailedFriends = detailedFriends
//        self._selectedFriend = selectedFriend
//        self.collectionViewController = collectionViewController
//    }
//
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return detailedFriends.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if indexPath.item == 0 || indexPath.item == detailedFriends.count - 1 {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddButtonCell.reuseIdentifier, for: indexPath) as! AddButtonCell
//            cell.onTap = { [weak self] in
//                NSLog("LOG: Add Button Tapped")
//            }
//            return cell
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCollectionViewCell.reuseIdentifier, for: indexPath) as! CustomCollectionViewCell
//            let friend = detailedFriends[indexPath.item]
//            cell.friend = friend
//            cell.onTap = { [weak self] in
//                self?.collectionViewController?.centerCell(at: indexPath)
//            }
//            cell.configure(with: friend)
//            return cell
//        }
//    }
//}
//

import UIKit
import SwiftUI

class CustomCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    @Binding var detailedFriends: [FriendRecord]
    @Binding var selectedFriend: FriendRecord?
    @Binding var isSheetPresented: Bool
    private weak var collectionViewController: CustomCollectionViewController?


    init(detailedFriends: Binding<[FriendRecord]>, selectedFriend: Binding<FriendRecord?>, isSheetPresented: Binding<Bool>, collectionViewController: CustomCollectionViewController) {
        self._detailedFriends = detailedFriends
        self._selectedFriend = selectedFriend
        self._isSheetPresented = isSheetPresented
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
            return cell
        } else {
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
}

