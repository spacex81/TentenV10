import UIKit

class BaseCell: UICollectionViewCell {
    // Common properties and methods
    private var previousIsPressing: Bool = false
    private var propertyAnimator: UIViewPropertyAnimator?

    var isPressing: Bool = false {
        didSet {
            if previousIsPressing != isPressing {
                animateScale()
                previousIsPressing = isPressing
            }
        }
    }

    func animateScale() {
        if isPressing {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } else {
            self.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }
        // Cancel any ongoing animation
        propertyAnimator?.stopAnimation(true)
        
        let scaleTransform: CGAffineTransform
        if isPressing {
            scaleTransform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        } else {
            scaleTransform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        
        // Create a new animator
        propertyAnimator = UIViewPropertyAnimator(
            duration: 0.4,
            dampingRatio: 0.6, // Adjust damping for bounce effect
            animations: {
                self.transform = scaleTransform
            }
        )
        
        // Start the animation
        propertyAnimator?.startAnimation()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = frame.size.width / 2
        contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
