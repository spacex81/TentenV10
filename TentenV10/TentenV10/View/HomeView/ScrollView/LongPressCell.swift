import UIKit

class LongPressCell: BaseCell {
    static let reuseIdentifier = "LongPressCell"
    var friend: FriendRecord?
    private let repoManager = RepositoryManager.shared

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
    
//    private let lockDistance: CGFloat = 100
    private let lockDistance: CGFloat = 50
    private var longPressGestureBeganPoint = CGPoint.zero
    
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    private var hasGivenFeedback = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didLongPressCell(_ gesture: UILongPressGestureRecognizer) {
        let locationInContentView = gesture.location(in: contentView)
        
        switch gesture.state {
        case .began:
            onLongPressBegan?() // Trigger the long press began callback
            viewModel.progress = 0
            longPressGestureBeganPoint = locationInContentView
            hasGivenFeedback = false
            
            guard let friend = friend else {return}
            repoManager.updateTimestampWhenLongPress(friendId: friend.id)
        case .changed:
            let verticalDistance = longPressGestureBeganPoint.y - locationInContentView.y
            let lockProgress = Float(verticalDistance / lockDistance)
            if lockProgress >= 1 {
                viewModel.isLocked = true
                if !hasGivenFeedback {
                    NSLog("LOG: impactOccurred")
                    feedback.impactOccurred()
                    hasGivenFeedback = true // Set the flag to true to prevent further feedback
                }
            } else {
                viewModel.progress = lockProgress
            }
        case .ended, .cancelled:
            onLongPressEnded?() // Trigger the long press ended callback
        default:
            break
        }
    }

    func configure(with friend: FriendRecord) {
        self.friend = friend
        
        if let imageData = friend.profileImageData {
            imageView.image = UIImage(data: imageData)
        } else {
            imageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
        
//        updateCellState()
    }
    
    private func updateCellState() {
        guard let friend = friend else { return }

        if friend.isBusy {
            longPressGestureRecognizer.isEnabled = false
        } else {
            longPressGestureRecognizer.isEnabled = true
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
