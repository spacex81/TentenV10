import UIKit

class AnimatedBackgroundView: UIView {
    private let imageView = UIImageView()
    private var currentImage: UIImage? // Store the current image

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
        guard let newImage = image else {
            imageView.image = nil
            currentImage = nil
            return
        }

        if let currentImage = currentImage, areImagesEqual(currentImage, newImage) {
            // If the image is the same as the current image, do nothing
            return
        }

        // Update the current image and animate the transition
        currentImage = newImage
        animateTransition(to: newImage)
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

    private func areImagesEqual(_ image1: UIImage, _ image2: UIImage) -> Bool {
        // Simple comparison of image sizes and pixel data
        guard image1.size == image2.size else { return false }
        
        guard let data1 = image1.pngData(), let data2 = image2.pngData() else { return false }
        return data1 == data2
    }

    func setPressingState(_ isPressing: Bool) {
        // Define the scale factor for shrinking
        let scaleFactor: CGFloat = isPressing ? 0.7 : 1.0 // 70% of the original size when pressing, 100% otherwise

        // Animate the scaling transformation
        UIView.animate(withDuration: 0.2) {
            self.imageView.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        }
    }
}
