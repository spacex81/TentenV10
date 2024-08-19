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
        imageView.layer.cornerRadius = 20
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

    private let blurEffectView = UIVisualEffectView(effect: nil)

    func setPressingState(_ isPressing: Bool) {
        let scaleXFactor: CGFloat = isPressing ? 0.8 : 1.0 // Shrink
        let scaleYFactor: CGFloat = isPressing ? 0.75 : 1.0 // Shrink

        UIView.animate(withDuration: 0.25) {
            self.imageView.transform = CGAffineTransform(scaleX: scaleXFactor, y: scaleYFactor)

            if isPressing {
                // Create and add the blur effect view if not already added
                if self.blurEffectView.superview == nil {
                    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
                    self.blurEffectView.effect = blurEffect
                    self.blurEffectView.frame = self.imageView.bounds
                    self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.imageView.addSubview(self.blurEffectView)
                }
                
                // Add wiggle animation
                let wiggleRotationAngle: CGFloat = .pi / 50 // Degrees
                let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
                animation.values = [-wiggleRotationAngle, wiggleRotationAngle, -wiggleRotationAngle] // Left and right rotations
                animation.keyTimes = [0, 0.5, 1] // Set the timing for each keyframe
                animation.duration = 0.3 // Duration of the wiggle animation
                animation.repeatCount = Float.infinity // Repeat indefinitely
                self.imageView.layer.add(animation, forKey: "wiggle")
            } else {
                // Remove the blur effect view
                self.blurEffectView.removeFromSuperview()
                
                // Stop the wiggle animation
                self.imageView.layer.removeAnimation(forKey: "wiggle")
            }
        }
    }
}
