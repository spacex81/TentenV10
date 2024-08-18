import UIKit

class LongPressCell: UICollectionViewCell {
    static let reuseIdentifier = "LongPressCell"
    
    var onLongPressBegan: (() -> Void)? // Closure to handle long press beginning
    var onLongPressEnded: (() -> Void)? // Closure to handle long press ending

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.layer.cornerRadius = frame.size.width / 2
        contentView.layer.masksToBounds = true
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        longPressGestureRecognizer.minimumPressDuration = 0.1
        longPressGestureRecognizer.addTarget(self, action: #selector(didLongPressCell))
        contentView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func didLongPressCell(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            onLongPressBegan?() // Trigger the long press began callback
        case .ended, .cancelled:
            onLongPressEnded?() // Trigger the long press ended callback
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with friend: FriendRecord) {
        if let imageData = friend.profileImageData {
            imageView.image = UIImage(data: imageData)
        } else {
            imageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }
}
