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
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)  // Make the text bold
        button.layer.cornerRadius = 24
        button.layer.masksToBounds = true
        button.addTarget(nil, action: #selector(changeImageAction), for: .touchUpInside)
        
        // Adding text shadow to changeButton
        button.titleLabel?.layer.shadowColor = UIColor.black.cgColor
        button.titleLabel?.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.titleLabel?.layer.shadowRadius = 3
        button.titleLabel?.layer.shadowOpacity = 0.5
        button.titleLabel?.layer.masksToBounds = false  // Allow shadow to go beyond label bounds
        
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)  // Bold text for cancel button
        
        // Adding text shadow to closeButton
        button.titleLabel?.layer.shadowColor = UIColor.black.cgColor
        button.titleLabel?.layer.shadowOffset = CGSize(width: 1, height: 1)
        button.titleLabel?.layer.shadowRadius = 3
        button.titleLabel?.layer.shadowOpacity = 0.5
        button.titleLabel?.layer.masksToBounds = false  // Allow shadow to go beyond label bounds
        
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
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50), // Adjust for lower placement
            buttonStack.heightAnchor.constraint(equalToConstant: 150), // Increased height for bigger buttons
            buttonStack.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.85) // Slightly shorter width
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
        // Present ImagePicker to choose an image
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        
        // Present the image picker
        self.present(picker, animated: true, completion: nil)
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

// Extension to handle image picker delegate methods
extension ImageBottomSheetViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            // Log original image size
            NSLog("LOG: Original image size: \(selectedImage.size.width)x\(selectedImage.size.height)")
            
            // Update the userRecord profile image with the resized image
            if var userRecord = repoManager.userRecord {
                
                // Resize the image if necessary
                var finalImage = selectedImage
                if selectedImage.size.width > maxImageSize.width || selectedImage.size.height > maxImageSize.height {
                    if let resizedImage = resizeImage(selectedImage, targetSize: maxImageSize) {
                        finalImage = resizedImage
                        // Log resized image size
                        NSLog("LOG: Resized image size: \(finalImage.size.width)x\(finalImage.size.height)")
                    } else {
                        NSLog("LOG: Error resizing image")
                        return
                    }
                } else {
                    // If no resizing was needed, log that info
                    NSLog("LOG: Image did not require resizing")
                }
                
                // Set profileImageData with resized image
                userRecord.profileImageData = finalImage.jpegData(compressionQuality: 0.8)
                
                // Update the repoManager's userRecord on the main thread
                DispatchQueue.main.async {
                    self.repoManager.userRecord = userRecord
                }
                
                NSLog("LOG: ImageBottomSheetViewController-changeImageAction: Profile image updated")
            }
        }
        picker.dismiss(animated: true) {
            // TODO: Instead of dismissing the whole bottom sheet
            // we need to dismiss only the image picker
//            self.dismissBottomSheet()
            picker.dismiss(animated: true, completion: nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
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
