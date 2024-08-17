//import UIKit
//import SwiftUI
//
//class CustomCollectionViewController: UIViewController, UICollectionViewDelegate {
//    var collectionView: UICollectionView!
//    var dataSource: CustomCollectionViewDataSource!
//
//    @Binding var selectedFriend: FriendRecord?
//    @Binding var detailedFriends: [FriendRecord]
//    @Binding var isSheetPresented: Bool
//    
//    init(selectedFriend: Binding<FriendRecord?>, detailedFriends: Binding<[FriendRecord]>, isSheetPresented: Binding<Bool>) {
//        self._selectedFriend = selectedFriend
//        self._detailedFriends = detailedFriends
//        self._isSheetPresented = isSheetPresented
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let layout = CustomCollectionViewFlowLayout()
//        layout.viewController = self
//
//        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        collectionView.backgroundColor = .clear
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        collectionView.showsHorizontalScrollIndicator = false
//        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: CustomCollectionViewCell.reuseIdentifier)
//        collectionView.register(AddButtonCell.self, forCellWithReuseIdentifier: AddButtonCell.reuseIdentifier)
//        collectionView.decelerationRate = .fast
//
//        dataSource = CustomCollectionViewDataSource(
//            detailedFriends: Binding(get: { self.updatedDetailedFriends(with: self.detailedFriends) }, set: { newFriends in
//                // Update the original detailedFriends if needed
//                self.detailedFriends = newFriends
//            }),
//            selectedFriend: $selectedFriend,
//            isSheetPresented: $isSheetPresented,
//            collectionViewController: self
//        )
//        collectionView.dataSource = dataSource
//        
//        collectionView.delegate = self
//        // Initialize and assign the data source
//
//        view.addSubview(collectionView)
//
//        NSLayoutConstraint.activate([
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ])
//    }
//    
//    private func centerInitialItem() {
//        // Ensure there are enough items to center
//        guard detailedFriends.count > 1 else { return }
//        
//        let initialIndexPath = IndexPath(item: 1, section: 0)
//        if let attributes = collectionView.layoutAttributesForItem(at: initialIndexPath) {
//            let collectionViewCenterX = collectionView.bounds.size.width / 2
//            let contentOffsetX = attributes.center.x - collectionViewCenterX
//            collectionView.setContentOffset(CGPoint(x: contentOffsetX, y: 0), animated: false)
//
//            // Update the selected profile image
//            DispatchQueue.main.async {
//                self.selectedFriend = self.detailedFriends[0]
//            }
//        }
//    }
//    
//    func centerCell(at indexPath: IndexPath) {
//        guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else { return }
//        
//        let collectionViewCenterX = collectionView.bounds.size.width / 2
//        let targetContentOffsetX = attributes.center.x - collectionViewCenterX
//        
//        // Start the spring animation directly
//        let springAnimationDuration: TimeInterval = 0.7
//        let springDamping: CGFloat = 0.5
//        
//        // Use UIViewPropertyAnimator to create a spring animation
//        let springAnimator = UIViewPropertyAnimator(duration: springAnimationDuration, dampingRatio: springDamping, animations: {
//            self.collectionView.setContentOffset(CGPoint(x: targetContentOffsetX, y: 0), animated: false)
//        })
//        
//        springAnimator.startAnimation()
//        
//        // Haptic feedback
//        let generator = UIImpactFeedbackGenerator(style: .medium)
//        generator.prepare()
//        generator.impactOccurred()
//        
//        // Update the selected profile image
//        DispatchQueue.main.async {
//            if let cell = self.collectionView.cellForItem(at: indexPath) as? CustomCollectionViewCell, let friend = cell.friend {
//                self.selectedFriend = friend
//            }
//        }
//    }
//
//    func reloadData() {
//        NSLog("LOG: reloadData")
//        collectionView.reloadData()
//    }
//    
//    private func updatedDetailedFriends(with friends: [FriendRecord]) -> [FriendRecord] {
//        var updatedFriends = [FriendRecord.empty] // Add empty at the beginning
//        updatedFriends.append(contentsOf: friends)
//        updatedFriends.append(FriendRecord.empty) // Add empty at the end
//        return updatedFriends
//    }
//}
//

import UIKit
import SwiftUI

class CustomCollectionViewController: UIViewController, UICollectionViewDelegate {
    var collectionView: UICollectionView!
    var dataSource: CustomCollectionViewDataSource!

    @Binding var selectedFriend: FriendRecord?
    @Binding var detailedFriends: [FriendRecord] 
    @Binding var isSheetPresented: Bool
    
    private var needToCenterInitialItem: Bool = true
    
    init(selectedFriend: Binding<FriendRecord?>, detailedFriends: Binding<[FriendRecord]>, isSheetPresented: Binding<Bool>) {
        self._selectedFriend = selectedFriend
        self._detailedFriends = detailedFriends
        self._isSheetPresented = isSheetPresented
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let layout = CustomCollectionViewFlowLayout()
        layout.viewController = self

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: CustomCollectionViewCell.reuseIdentifier)
        collectionView.register(AddButtonCell.self, forCellWithReuseIdentifier: AddButtonCell.reuseIdentifier)
        collectionView.decelerationRate = .fast

        dataSource = CustomCollectionViewDataSource(
            detailedFriends: Binding(get: { self.updatedDetailedFriends(with: self.detailedFriends) }, set: { newFriends in
                // Update the original detailedFriends if needed
                self.detailedFriends = newFriends
            }),
            selectedFriend: $selectedFriend,
            isSheetPresented: $isSheetPresented,
            collectionViewController: self
        )
        collectionView.dataSource = dataSource
        
        collectionView.delegate = self
        // Initialize and assign the data source

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func centerInitialItem() {
        // Ensure there are enough items to center
        guard detailedFriends.count > 1 else { 
            NSLog("LOG: number of fetched friends need to be bigger than 1")
            return }
        NSLog("LOG: centerInitialItem")
        
        let initialIndexPath = IndexPath(item: 1, section: 0)
        NSLog("LOG: 1")
        DispatchQueue.main.async {
            self.selectedFriend = self.detailedFriends[0]
        }
    }
    
    func centerCell(at indexPath: IndexPath) {
        guard let attributes = collectionView.layoutAttributesForItem(at: indexPath) else { return }
        
        let collectionViewCenterX = collectionView.bounds.size.width / 2
        let targetContentOffsetX = attributes.center.x - collectionViewCenterX
        
        // Start the spring animation directly
        let springAnimationDuration: TimeInterval = 0.7
        let springDamping: CGFloat = 0.5
        
        // Use UIViewPropertyAnimator to create a spring animation
        let springAnimator = UIViewPropertyAnimator(duration: springAnimationDuration, dampingRatio: springDamping, animations: {
            self.collectionView.setContentOffset(CGPoint(x: targetContentOffsetX, y: 0), animated: false)
        })
        
        springAnimator.startAnimation()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        // Update the selected profile image
        DispatchQueue.main.async {
            if let cell = self.collectionView.cellForItem(at: indexPath) as? CustomCollectionViewCell, let friend = cell.friend {
                self.selectedFriend = friend
            }
        }
    }

    func reloadData() {
        collectionView.reloadData()
    }
    
    private func updatedDetailedFriends(with friends: [FriendRecord]) -> [FriendRecord] {
        var updatedFriends = [FriendRecord.empty] // Add empty at the beginning
        updatedFriends.append(contentsOf: friends)
        updatedFriends.append(FriendRecord.empty) // Add empty at the end
        NSLog("LOG: count: \(updatedFriends.count)")
        if updatedFriends.count > 3, needToCenterInitialItem {
            NSLog("LOG: HO")
            centerInitialItem()
            needToCenterInitialItem = false
        }
        return updatedFriends
    }
}

