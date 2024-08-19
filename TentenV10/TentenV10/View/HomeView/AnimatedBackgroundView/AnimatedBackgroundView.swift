import UIKit

class AnimatedBackgroundView: UIView {
    private let imageView = UIImageView()
    private var initialImage: UIImage?
    private var animationInProgress = false
    private var currentAnimator: UIViewPropertyAnimator?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupImageView()
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func setImage(_ image: UIImage?) {
        guard let image = image else {
            imageView.image = nil
            return
        }

        if initialImage == nil {
            initialImage = image
        }

        // If the image is already the same, do nothing
        if imageView.image == image {
            return
        }

        // Animate the transition to the new image
        animateTransition(to: image)
    }

    private func animateTransition(to image: UIImage) {
        let transitionView = UIImageView(image: image)
        transitionView.contentMode = .scaleAspectFill
        transitionView.clipsToBounds = true
        transitionView.frame = bounds
        transitionView.alpha = 0
        transitionView.transform = CGAffineTransform(scaleX: 1.2, y: 1.0) // Start with larger image horizontally
        addSubview(transitionView)

        UIView.animate(withDuration: 0.2, animations: {
            transitionView.alpha = 1
            transitionView.transform = CGAffineTransform.identity // Scale down to original size
        }) { _ in
            // Remove the transition view once the animation completes
            transitionView.removeFromSuperview()

            // Set the new image to the imageView after the transition completes
            self.imageView.image = image
        }
    }

}
