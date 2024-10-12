import UIKit

final class ImageBottomSheetViewController: UIViewController {
    
    var onDismiss: (() -> Void)?
    let repoManager = RepositoryManager.shared
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.0)
        view.alpha = 0
        return view
    }()
    
    // Custom button with hue-rotating gradient background
    private let changeButton: GradientButton = {
        let button = GradientButton(type: .system)
        button.setTitle("사진 바꾸기", for: .normal)
        button.setTitleColor(.white, for: .normal) // Set text color
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.addTarget(nil, action: #selector(changeImageAction), for: .touchUpInside)
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.addTarget(nil, action: #selector(dismissBottomSheet), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupGesture()
        changeButton.startHueRotation()  // Start hue rotation when view loads
    }
    
    private func setupViews() {
        view.addSubview(dimmingView)
        view.addSubview(contentView)
        
        dimmingView.frame = view.bounds
        
        // Get the profile image from the userRecord and set it as the background
        if let imageData = repoManager.userRecord?.profileImageData, let profileImage = UIImage(data: imageData) {
            let imageView = UIImageView(image: profileImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            contentView.insertSubview(imageView, at: 0)

            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        } else {
            contentView.backgroundColor = .systemGray // Fallback color
        }
        
        let height = view.frame.height * 1.0
        contentView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)

        // Create a vertical stack for buttons
        let buttonStack = UIStackView(arrangedSubviews: [changeButton, closeButton])
        buttonStack.axis = .vertical
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        
        contentView.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 100),
            buttonStack.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8)
        ])
        
        UIView.animate(withDuration: 0.3) {
            self.contentView.frame.origin.y = self.view.frame.height - height
            self.dimmingView.alpha = 1
        }
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func changeImageAction() {
        self.dismissBottomSheet()
    }
    
    @objc private func dismissBottomSheet() {
        UIView.animate(withDuration: 0.3, animations: {
            self.contentView.frame.origin.y = self.view.frame.height
            self.dimmingView.alpha = 0
        }) { _ in
            self.contentView.removeFromSuperview()
            self.dimmingView.removeFromSuperview()
            self.onDismiss?()
            self.changeButton.stopHueRotation()  // Stop the hue rotation when dismissed
        }
    }
}

// Custom UIButton with hue-rotating gradient background
class GradientButton: UIButton {
    private let gradientLayer = CAGradientLayer()
    private var hue: CGFloat = 0.0
    private var hueRotationTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradientLayer()
    }
    
    private func setupGradientLayer() {
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.colors = [
            UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor,
            UIColor(hue: hue + 0.1, saturation: 1, brightness: 1, alpha: 1).cgColor
        ]
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds  // Ensure the gradient layer matches the button's bounds
    }
    
    func startHueRotation() {
        hueRotationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            self.hue += 0.01
            if self.hue > 1.0 { self.hue = 0.0 }
            self.updateGradientColors()
        }
    }
    
    func stopHueRotation() {
        hueRotationTimer?.invalidate()
        hueRotationTimer = nil
    }
    
    private func updateGradientColors() {
        gradientLayer.colors = [
            UIColor(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor,
            UIColor(hue: (hue + 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 1, brightness: 1, alpha: 1).cgColor
        ]
    }
}
