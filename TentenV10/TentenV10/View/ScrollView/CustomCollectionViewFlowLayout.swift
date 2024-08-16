import UIKit

class CustomCollectionViewFlowLayout: UICollectionViewFlowLayout {
    let standardItemScale: CGFloat = 0.8
    let shrinkedItemScale: CGFloat = 0.5
    let standardItemSpacing: CGFloat = 10

    private var previousCenterX: CGFloat?

    weak var viewController: CustomCollectionViewController?

    override init() {
        super.init()
        scrollDirection = .horizontal
        minimumLineSpacing = standardItemSpacing
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func prepare() {
        super.prepare()
        
        // Calculate item size so that three items fit the screen width
        let screenWidth = collectionView!.bounds.width
        let totalSpacing = standardItemSpacing * 2 // 2 gaps of 10 points each
        let itemWidth = (screenWidth - totalSpacing) / 3.0

        itemSize = CGSize(width: itemWidth, height: itemWidth)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributesArray = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let screenWidth = collectionView!.bounds.width
        let centerX = visibleRect.midX

        for attributes in attributesArray {
            let itemCenterX = attributes.center.x
            let distanceFromCenter = abs(centerX - itemCenterX)
            let positionPercentage = (itemCenterX - visibleRect.origin.x) / screenWidth

            let scale: CGFloat

            if positionPercentage <= 0.1 {
                // Zone 1 (0% to 10%): Shrink proportionately
                let distanceToShrink = positionPercentage * 10
                scale = shrinkedItemScale + (standardItemScale - shrinkedItemScale) * distanceToShrink
            } else if positionPercentage >= 0.9 {
                // Zone 3 (90% to 100%): Shrink proportionately
                let distanceToShrink = (1.0 - positionPercentage) * 10
                scale = shrinkedItemScale + (standardItemScale - shrinkedItemScale) * distanceToShrink
            } else {
                // Zone 2 (10% to 90%): Maintain standard size
                scale = standardItemScale
            }

            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)

            // Determine if the item is approaching the center
            if distanceFromCenter < 50 {
                if previousCenterX == nil || previousCenterX != attributes.center.x {
                    // Trigger haptic feedback only for the new item approaching the center
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.prepare()
                    generator.impactOccurred()

                    previousCenterX = attributes.center.x
                }
            }
        }

        return attributesArray
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let targetRect = CGRect(origin: proposedContentOffset, size: collectionView!.bounds.size)
        guard let attributesArray = super.layoutAttributesForElements(in: targetRect) else {
            return proposedContentOffset
        }

        let centerX = proposedContentOffset.x + collectionView!.bounds.width / 2
        var closestAttribute: UICollectionViewLayoutAttributes?

        for attributes in attributesArray {
            if closestAttribute == nil || abs(attributes.center.x - centerX) < abs(closestAttribute!.center.x - centerX) {
                closestAttribute = attributes
            }
        }

        guard let closestAttr = closestAttribute else {
            return proposedContentOffset
        }

        let offsetX = closestAttr.center.x - collectionView!.bounds.width / 2

        // Adding spring animation on scroll
        let springAnimationDuration: TimeInterval = 0.7
        let springDamping: CGFloat = 0.5
        let initialSpringVelocity: CGFloat = 0.5
        
        DispatchQueue.main.async {
            let springAnimator = UIViewPropertyAnimator(duration: springAnimationDuration, dampingRatio: springDamping, animations: {
                self.collectionView?.setContentOffset(CGPoint(x: offsetX, y: proposedContentOffset.y), animated: false)
            })
            springAnimator.startAnimation()

            // Update the selected profile image when snapping
            if let indexPath = self.collectionView?.indexPathForItem(at: closestAttr.center),
               let friend = self.viewController?.detailedFriends[indexPath.item] {
                self.viewController?.selectedFriend = friend
            }
        }

        return CGPoint(x: offsetX, y: proposedContentOffset.y)
    }
}
