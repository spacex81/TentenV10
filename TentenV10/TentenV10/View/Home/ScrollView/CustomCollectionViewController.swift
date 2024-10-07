import UIKit
import SwiftUI

class CustomCollectionViewController: UIViewController, UICollectionViewDelegate {
    var collectionView: UICollectionView!
    var dataSource: CustomCollectionViewDataSource!
    let repoManager = RepositoryManager.shared

    @Binding var selectedFriend: FriendRecord?
    @Binding var detailedFriends: [FriendRecord]
    @Binding var isSheetPresented: Bool
    @Binding var isPressing: Bool
    @Binding var isPublished: Bool
    @Binding var isLocked: Bool
    
    private var needToCenterInitialItem: Bool = true
    
    init(
        selectedFriend: Binding<FriendRecord?>,
        detailedFriends: Binding<[FriendRecord]>,
        isSheetPresented: Binding<Bool>,
        isPressing: Binding<Bool>,
        isPublished: Binding<Bool>,
        isLocked: Binding<Bool>
    ) {
    self._selectedFriend = selectedFriend
        self._detailedFriends = detailedFriends
        self._isSheetPresented = isSheetPresented
        self._isPressing = isPressing
        self._isPublished = isPublished
        self._isLocked = isLocked
        super.init(nibName: nil, bundle: nil)
        
        RepositoryManager.shared.collectionViewController = self
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
        collectionView.register(TapCell.self, forCellWithReuseIdentifier: TapCell.reuseIdentifier)
        collectionView.register(LongPressCell.self, forCellWithReuseIdentifier: LongPressCell.reuseIdentifier)
        collectionView.register(AddButtonCell.self, forCellWithReuseIdentifier: AddButtonCell.reuseIdentifier)
        collectionView.decelerationRate = .fast

        dataSource = CustomCollectionViewDataSource(
            detailedFriends: Binding(get: { self.updatedDetailedFriends(with: self.repoManager.detailedFriends) }, set: { newFriends in
            }),
            selectedFriend: $selectedFriend,
            isSheetPresented: $isSheetPresented,
            isPressing: $isPressing,
            isLocked: $isLocked,
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
    
    // MARK: Used when tap to center
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
    }

    func reloadData() {
        NSLog("LOG: CustomCollectionViewController-reloadData()")
        
        let itemCount = collectionView.numberOfItems(inSection: 0)
        NSLog("LOG: itemCount: \(itemCount)")
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.collectionView.collectionViewLayout.invalidateLayout() // Invalidate layout to force update
            self.collectionView.layoutIfNeeded() // Ensure layout is updated immediately
        }
    }
    
    private func updatedDetailedFriends(with friends: [FriendRecord]) -> [FriendRecord] {
//        NSLog("LOG: updatedDetailedFriends")
        var updatedFriends = [FriendRecord.empty] // Add empty at the beginning
        
        // Iterate over the input friends array
        for friend in friends {
            // Check if the friend is already in the updatedFriends array
            if !updatedFriends.contains(where: { $0.id == friend.id }) {
                updatedFriends.append(friend)
            }
        }
        
        updatedFriends.append(FriendRecord.empty) // Add empty at the end
//        print(updatedFriends)
        return updatedFriends
    }
}

