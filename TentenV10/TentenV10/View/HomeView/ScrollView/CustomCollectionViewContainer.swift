import UIKit
import SwiftUI

class CustomCollectionViewContainer: UIView {
    private let collectionViewController: CustomCollectionViewController
    private let containerView = UIView()

    init(selectedFriend: Binding<FriendRecord?>, detailedFriends: Binding<[FriendRecord]>, isSheetPresented: Binding<Bool>, isPressing: Binding<Bool>, isPublished: Binding<Bool>, isLocked: Binding<Bool>) {
        self.collectionViewController = CustomCollectionViewController(
            selectedFriend: selectedFriend,
            detailedFriends: detailedFriends,
            isSheetPresented: isSheetPresented,
            isPressing: isPressing,
            isPublished: isPublished,
            isLocked: isLocked
        )

        super.init(frame: .zero)

        setupCollectionViewController()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCollectionViewController() {
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Add the collection view controller's view to the container view
        let collectionView = collectionViewController.view!
        containerView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: containerView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    func updateDetailedFriends(_ detailedFriends: [FriendRecord]) {
        DispatchQueue.main.async {
            self.collectionViewController.detailedFriends = detailedFriends
            self.collectionViewController.reloadData()
        }
    }
}

extension CustomCollectionViewContainer {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self {
            return collectionViewController.collectionView
        }
        return view
    }
}

