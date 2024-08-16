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

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 70)
        layout.minimumLineSpacing = 20

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: CustomCollectionViewCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false

        // Initialize and assign the data source
        dataSource = CustomCollectionViewDataSource(detailedFriends: $detailedFriends, selectedFriend: $selectedFriend)
        collectionView.dataSource = dataSource

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}
