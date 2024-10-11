import UIKit

class AnimatedBackgroundView: UIView {
    private let imageView = UIImageView()
    private var currentImage: UIImage? // Store the current image
    private let blurEffectView = UIVisualEffectView(effect: nil)
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var feedbackTimer: Timer? // Timer for continuous haptic feedback

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
        impactFeedbackGenerator.prepare() // Prepare the feedback generator
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupImageView()
        impactFeedbackGenerator.prepare() // Prepare the feedback generator
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

        UIView.animate(withDuration: 0.1, animations: {
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

    func setPressingState(_ isPressing: Bool, _ isPublished: Bool) {
        let scaleXFactor: CGFloat
        let scaleYFactor: CGFloat
        let cornerRadius: CGFloat
        
        if isPressing && !isPublished {
            // case 1
            scaleXFactor = 0.85
            scaleYFactor = 0.75
            cornerRadius = 50
        } else if isPublished {
            // case 2
            scaleXFactor = 0.95
            scaleYFactor = 0.85
            cornerRadius = 50
        } else {
            // case 3
            scaleXFactor = 1.0
            scaleYFactor = 1.0
            cornerRadius = 0
        }

        UIView.animate(withDuration: 0.3) {
            self.imageView.transform = CGAffineTransform(scaleX: scaleXFactor, y: scaleYFactor)
            self.imageView.layer.cornerRadius = cornerRadius
            
            NSLog("LOG: Start wiggle animation")
            NSLog("LOG: Wiggle-isPressing is \(isPressing)")
            NSLog("LOG: Wiggle-isPublished is \(isPublished)")
            
            if isPressing && !isPublished {
                
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

                // Trigger continuous haptic feedback
                self.startHapticFeedback()
            } else {
                // Remove the blur effect view
                self.blurEffectView.removeFromSuperview()
                
                // Stop the wiggle animation
                self.imageView.layer.removeAnimation(forKey: "wiggle")
                
                // Stop continuous haptic feedback
                self.stopHapticFeedback()
            }
        }
    }

    private func startHapticFeedback() {
        feedbackTimer?.invalidate() // Invalidate any existing timer
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.impactFeedbackGenerator.impactOccurred()
        }
    }

    private func stopHapticFeedback() {
        feedbackTimer?.invalidate() // Invalidate the timer
        feedbackTimer = nil
    }
}
