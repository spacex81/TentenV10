import UIKit

class AddButtonCell: BaseCell {
    static let reuseIdentifier = "AddButtonCell"

    var onTap: (() -> Void)?

    private let addButton: UIButton = {
        let button = UIButton()
        let originalImage = UIImage(systemName: "plus")?.scaled(to: CGSize(width: 50, height: 50))
        let tintedImage = originalImage?.withTintColor(.white)
        
        button.setImage(tintedImage, for: .normal)
        button.layer.borderColor = UIColor.gray.cgColor
        button.backgroundColor = UIColor(white: 0.3, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)


    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(addButton)

        NSLayoutConstraint.activate([
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        addButton.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTapButton() {
        impactFeedbackGenerator.impactOccurred()
        onTap?() // Trigger the tap callback
    }

    override func applyScaleTransform(_ transform: CGAffineTransform) {
        propertyAnimator = UIViewPropertyAnimator(
            duration: 0.4,
            dampingRatio: 0.6, // Adjust damping for bounce effect
            animations: {
                self.addButton.transform = transform
            }
        )

        // Start the animation
        propertyAnimator?.startAnimation()
    }
}

extension UIImage {
    func scaled(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage ?? self
    }
    
    // TODO: setImageColor
    func withTintColor(_ color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            context.fill(rect)
            
            draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        }
    }
}

