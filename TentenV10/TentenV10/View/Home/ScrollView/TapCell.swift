import UIKit

class TapCell: BaseCell {
    static let reuseIdentifier = "TapCell"
    var friend: FriendRecord?

    var onTap: (() -> Void)? // Closure to handle tap event

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()

    private let tapGestureRecognizer = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        tapGestureRecognizer.addTarget(self, action: #selector(didTapCell))
        contentView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTapCell() {
        onTap?() // Trigger the tap callback
    }

    func configure(with friend: FriendRecord) {
        self.friend = friend
        
        if let imageData = friend.profileImageData {
            imageView.image = UIImage(data: imageData)
        } else {
            imageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }
    

    override func applyScaleTransform(_ transform: CGAffineTransform) {
        propertyAnimator = UIViewPropertyAnimator(
            duration: 0.4,
            dampingRatio: 0.6, // Adjust damping for bounce effect
            animations: {
                self.imageView.transform = transform
            }
        )

        // Start the animation
        propertyAnimator?.startAnimation()
    }
}
