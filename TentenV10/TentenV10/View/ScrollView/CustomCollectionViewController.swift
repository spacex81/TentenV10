import UIKit
import SwiftUI

class CustomCollectionViewController: UIViewController, UICollectionViewDelegate {
    var collectionView: UICollectionView!
    var dataSource: CustomCollectionViewDataSource!

    @Binding var selectedFriend: FriendRecord?
    @Binding var detailedFriends: [FriendRecord]

    init(selectedFriend: Binding<FriendRecord?>, detailedFriends: Binding<[FriendRecord]>) {
        self._selectedFriend = selectedFriend
        self._detailedFriends = detailedFriends
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
        collectionView.decelerationRate = .fast

        dataSource = CustomCollectionViewDataSource(detailedFriends: $detailedFriends, selectedFriend: $selectedFriend, collectionViewController: self)
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
    
    func centerCell(at indexPath: IndexPath) {
        // Check if the indexPath is the first or last item
        if indexPath.item == 0 || indexPath.item == detailedFriends.count - 1 {
            print("Add button tapped")
            return
        }
        
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

}
