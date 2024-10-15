import UIKit

class LongPressCell: BaseCell {
    static let reuseIdentifier = "LongPressCell"
    var friend: FriendRecord?

    var onLongPressBegan: (() -> Void)? // Closure to handle long press beginning
    var onLongPressEnded: (() -> Void)? // Closure to handle long press ending

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()

    let longPressGestureRecognizer = UILongPressGestureRecognizer()
    
//    private let lockDistance: CGFloat = 100
    private let lockDistance: CGFloat = 50
    private var longPressGestureBeganPoint = CGPoint.zero
    
    // MARK: Haptic
    private let feedback = UIImpactFeedbackGenerator(style: .medium)
    private var hasGivenFeedback = false
    //
    
    // MARK: Time limit
    private var timer: Timer? // Timer for limiting long press duration
    private let longPressDurationLimit: TimeInterval = 10
    //

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

//        longPressGestureRecognizer.minimumPressDuration = 0.1
        longPressGestureRecognizer.minimumPressDuration = 0.05
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
//            NSLog("LOG: didLongPressCell-began")
            onLongPressBegan?() // Trigger the long press began callback
            viewModel.progress = 0
            longPressGestureBeganPoint = locationInContentView
            hasGivenFeedback = false
            
            guard let friend = friend else {return}
            repoManager.updateFirebaseWhenLongPressStart(friendId: friend.id)
            
            // Start a timer to automatically end the long press after 15 seconds
            timer?.invalidate() // Invalidate any existing timer
            timer = Timer.scheduledTimer(withTimeInterval: longPressDurationLimit, repeats: false) { [weak self] _ in
                self?.endLongPressDueToTimeout()
            }
        case .changed:
//            NSLog("LOG: didLongPressCell-changed")
            let verticalDistance = longPressGestureBeganPoint.y - locationInContentView.y
            let lockProgress = Float(verticalDistance / lockDistance)
            if lockProgress >= 1 && viewModel.isPublished {
                viewModel.isLocked = true
                if !hasGivenFeedback {
//                    NSLog("LOG: impactOccurred")
                    feedback.impactOccurred()
                    hasGivenFeedback = true // Set the flag to true to prevent further feedback
                }
            } else {
                viewModel.progress = lockProgress
            }
        case .ended, .cancelled:
//            NSLog("LOG: didLongPressCell-ended or cancelled")
            onLongPressEnded?() // Trigger the long press ended callback
            
            guard let friend = friend else {return}
            repoManager.updateFirebaseWhenLongPressEnd(friendId: friend.id)
        default:
            break
        }
    }
    
    private func endLongPressDueToTimeout() {
        // TODO: Check if friend is suspended
        
        // Simulate the end of the long press if 15 seconds passed
        onLongPressEnded?() // Trigger the long press ended callback
        guard let friend = friend else { return }
        repoManager.updateFirebaseWhenLongPressEnd(friendId: friend.id)
        
        // Invalidate the timer as it's no longer needed
        timer?.invalidate()
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
    
//    private func updateCellState() {
//        guard let friend = friend else { return }
//
//        if friend.isBusy {
//            longPressGestureRecognizer.isEnabled = false
//        } else {
//            if !longPressGestureRecognizer.isEnabled {
//                longPressGestureRecognizer.isEnabled = true
//            }
//        }
//    }
    

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
