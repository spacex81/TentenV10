import UIKit

class BaseCell: UICollectionViewCell {
    // Common properties and methods
    private var previousIsPressing: Bool = false
    private var previousIsLocked: Bool = false
    private var previousShrinkWhenListening: Bool = false
    var propertyAnimator: UIViewPropertyAnimator?
    let viewModel = HomeViewModel.shared
    let repoManager = RepositoryManager.shared

    // set true when repoManager.currentState is .isListening and when cell is not long press
    var shrinkWhenListening: Bool = false {
        didSet {
            if previousShrinkWhenListening != shrinkWhenListening {
                animateScale()
                previousShrinkWhenListening = shrinkWhenListening
            }
        }
    }
    
    var isPressing: Bool = false {
        didSet {
            if previousIsPressing != isPressing {
                animateScale()
                previousIsPressing = isPressing
            }
        }
    }

    var isLocked: Bool = false {
        didSet {
            if previousIsLocked != isLocked {
                animateScale()
                previousIsLocked = isLocked
            }
        }
    }
    
    // Updated animateScale function
    func animateScale() {
        NSLog("LOG: animateScale")
        
        // Cancel any ongoing animation
        propertyAnimator?.stopAnimation(true)
        
        let scaleTransform: CGAffineTransform
        if isPressing || isLocked || shrinkWhenListening {
            scaleTransform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            NSLog("LOG: Shrink")
        } else {
            scaleTransform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            NSLog("LOG: Scale")
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
