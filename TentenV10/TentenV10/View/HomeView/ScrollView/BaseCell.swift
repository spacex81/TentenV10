import UIKit

class BaseCell: UICollectionViewCell {
    // Common properties and methods
    private var previousIsPressing: Bool = false
    var propertyAnimator: UIViewPropertyAnimator?

    var isPressing: Bool = false {
        didSet {
            if previousIsPressing != isPressing {
                animateScale()
                previousIsPressing = isPressing
            }
        }
    }

    // new
    func animateScale() {
        // Cancel any ongoing animation
        propertyAnimator?.stopAnimation(true)
        
        let scaleTransform: CGAffineTransform
        if isPressing {
            scaleTransform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        } else {
            scaleTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }
        
        // Apply the scale transformation to the appropriate subview
        applyScaleTransform(scaleTransform)
    }

    // Placeholder method to be overridden by subclasses
    func applyScaleTransform(_ transform: CGAffineTransform) {
        // This method will be overridden in subclasses
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
