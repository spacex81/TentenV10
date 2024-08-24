import UIKit

class LockView: UIView {
    
    let backgroundImageView = UIImageView(image: UIImage(named: "bg_recorder_lock"))
    let lockShackleImageView = UIImageView(image: UIImage(named: "ic_recorder_lock_shackle"))
    let lockBodyImageView = UIImageView(image: UIImage(named: "ic_recorder_lock_body"))
    let directionIndicatorImageView = UIImageView(image: UIImage(named: "ic_recorder_lock_direction_up"))
    
    
    var isLocked = false {
        didSet {
            backgroundImageView.isHidden = isLocked
            lockShackleImageView.isHidden = isLocked
            lockBodyImageView.isHidden = isLocked
            directionIndicatorImageView.isHidden = isLocked
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return BackgroundSize.start
    }
    
    var progress: Float = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepare()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isLocked {
            let progress = max(0, min(1, CGFloat(self.progress)))
            
            let centerX = (bounds.width - BackgroundSize.start.width) / 2

            // Calculate the background origin and size
            let backgroundOriginX = BackgroundOrigin.start.x + (BackgroundOrigin.end.x - BackgroundOrigin.start.x) * progress
            let backgroundOriginY = BackgroundOrigin.start.y + (BackgroundOrigin.end.y - BackgroundOrigin.start.y) * progress
            let backgroundWidth = BackgroundSize.start.width + (BackgroundSize.end.width - BackgroundSize.start.width) * progress
            let backgroundHeight = BackgroundSize.start.height + (BackgroundSize.end.height - BackgroundSize.start.height) * progress

            backgroundImageView.frame = CGRect(
                origin: CGPoint(x: centerX + backgroundOriginX, y: backgroundOriginY),
                size: CGSize(width: backgroundWidth, height: backgroundHeight)
            )

            // Calculate the lock body center
            let lockBodyCenterX = LockBodyCenter.start.x + (LockBodyCenter.end.x - LockBodyCenter.start.x) * progress
            let lockBodyCenterY = LockBodyCenter.start.y + (LockBodyCenter.end.y - LockBodyCenter.start.y) * progress
            lockBodyImageView.center = CGPoint(x: centerX + lockBodyCenterX, y: lockBodyCenterY)

            // Calculate the lock shackle center
            let lockShackleCenterX = LockShackleCenter.start.x + (LockShackleCenter.end.x - LockShackleCenter.start.x) * progress
            let lockShackleCenterY = LockShackleCenter.start.y + (LockShackleCenter.end.y - LockShackleCenter.start.y) * progress
            lockShackleImageView.center = CGPoint(x: centerX + lockShackleCenterX, y: lockShackleCenterY)

            // Calculate the direction indicator center
            let directionIndicatorCenterX = DirectionIndicatorCenter.start.x + (DirectionIndicatorCenter.end.x - DirectionIndicatorCenter.start.x) * progress
            let directionIndicatorCenterY = DirectionIndicatorCenter.start.y + (DirectionIndicatorCenter.end.y - DirectionIndicatorCenter.start.y) * progress
            directionIndicatorImageView.center = CGPoint(x: centerX + directionIndicatorCenterX, y: directionIndicatorCenterY)

            // Adjust alpha based on progress
            directionIndicatorImageView.alpha = 1 - progress
        }
    }
    
    private func prepare() {
        bounds.size = BackgroundSize.start
        progress = 0
        isLocked = false
        addSubview(backgroundImageView)
        addSubview(lockShackleImageView)
        addSubview(lockBodyImageView)
        addSubview(directionIndicatorImageView)
    }
    
    
    // Helper function to get image sizes
    private func imageSize(for imageName: String) -> CGSize {
        return UIImage(named: imageName)?.size ?? .zero
    }
}

extension LockView {
    
    static let verticalDistance: CGFloat = 50

    // Use instance methods or properties to get sizes
    private static var shackleImageSize: CGSize {
        return LockView().imageSize(for: "ic_recorder_lock_shackle")
    }

    private static var lockBodyImageSize: CGSize {
        return LockView().imageSize(for: "ic_recorder_lock_body")
    }

    static var lockedLockSize: CGSize {
        return CGSize(
            width: max(shackleImageSize.width, lockBodyImageSize.width),
            height: shackleImageSize.height + lockBodyImageSize.height + ShackleBottomMargin.end
        )
    }
    
    enum BackgroundOrigin {
        static let start = CGPoint(x: 0, y: 0)
        static let end = CGPoint(x: 0, y: start.y - verticalDistance)
    }
    
    enum BackgroundSize {
        static let start = CGSize(width: UIImage(named: "bg_recorder_lock")?.size.width ?? 0, height: 150)
        static let end = UIImage(named: "bg_recorder_lock")?.size ?? .zero
    }
    
    
    enum DirectionIndicatorTopMargin {
        static let start: CGFloat = 20
        static let end: CGFloat = 8
    }
    
    enum ShackleBottomMargin {
        static let start: CGFloat = -1
        static let end: CGFloat = -5
    }
    
    enum LockBodyCenter {
        static let start = CGPoint(x: BackgroundSize.start.width / 2, y: BackgroundSize.start.height / 2 - 20)
        static let end = CGPoint(x: BackgroundSize.end.width / 2, y: BackgroundSize.end.height - (BackgroundSize.end.height - lockedLockSize.height) / 2 - lockBodyImageSize.height / 2 - verticalDistance)
    }
    
    enum LockShackleCenter {
        static let start = CGPoint(x: BackgroundSize.start.width / 2, y: LockBodyCenter.start.y - shackleImageSize.height / 2 - lockBodyImageSize.height / 2 - ShackleBottomMargin.start)
        static let end = CGPoint(x: BackgroundSize.end.width / 2, y: (BackgroundSize.end.height - lockedLockSize.height) / 2 + shackleImageSize.height / 2 - verticalDistance)
    }
    
    enum DirectionIndicatorCenter {
        static let start = CGPoint(x: BackgroundSize.start.width / 2, y: LockBodyCenter.start.y + DirectionIndicatorTopMargin.start + (UIImage(named: "ic_recorder_lock_direction_up")?.size.height ?? 0))
        static let end = CGPoint(x: BackgroundSize.end.width / 2, y: LockBodyCenter.end.y + DirectionIndicatorTopMargin.end + (UIImage(named: "ic_recorder_lock_direction_up")?.size.height ?? 0))
    }
}
