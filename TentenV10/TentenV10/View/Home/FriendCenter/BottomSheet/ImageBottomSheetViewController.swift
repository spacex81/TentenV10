import UIKit

final class ImageBottomSheetViewController: UIViewController, UIScrollViewDelegate {
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var onDismiss: (() -> Void)?
    let repoManager = RepositoryManager.shared
    private var profileImageView: UIImageView? // Image view for profile image
    
    private var isImageSelected = false  // State to track if image is selected
    
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
    
    // ScrollView to allow zooming and panning
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    // Custom button with hue-rotating gradient background
    private let changeButton: GradientButton = {
        let button = GradientButton(type: .system)
        button.setTitle("사진 선택하기", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)  // Make the text bold
        button.layer.cornerRadius = 30
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
        
        // Add scrollView to the contentView
        contentView.addSubview(scrollView)
        scrollView.delegate = self  // Set the scroll view delegate to self
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Create profile image view and add it to the scrollView
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.clipsToBounds = true
        scrollView.addSubview(profileImageView)
        self.profileImageView = profileImageView
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            profileImageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            profileImageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            profileImageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            profileImageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),  // Ensure image view matches scroll view width
            profileImageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)  // Ensure image view matches scroll view height
        ])
        
        if let imageData = repoManager.userRecord?.profileImageData {
            updateProfileImage(imageData: imageData)  // Call this method to initially set the image
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
    
//    private func updateProfileImage() {
//        // Check if the userRecord has profile image data, and update the image view accordingly
//        if let imageData = repoManager.userRecord?.profileImageData, let profileImage = UIImage(data: imageData) {
//            profileImageView?.image = profileImage
//            NSLog("LOG: Profile image updated in ImageBottomSheet")
//        } else {
//            profileImageView?.image = nil // Remove image if no data is available
//            contentView.backgroundColor = .systemGray  // Fallback color if no image
//        }
//    }
    private func updateProfileImage(imageData: Data) {
        // Check if the userRecord has profile image data, and update the image view accordingly
//        if let imageData = repoManager.userRecord?.profileImageData, let profileImage = UIImage(data: imageData) {
//            profileImageView?.image = profileImage
//            NSLog("LOG: Profile image updated in ImageBottomSheet")
//        } else {
//            profileImageView?.image = nil // Remove image if no data is available
//            contentView.backgroundColor = .systemGray  // Fallback color if no image
//        }
        
        let profileImage = UIImage(data: imageData)
        profileImageView?.image = profileImage
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func changeImageAction() {
        impactFeedback.impactOccurred()
        
        if isImageSelected {
            uploadProfileImageToFirebase()
        } else {
            // Present ImagePicker to choose an image
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            
            // Present the image picker
            self.present(picker, animated: true, completion: nil)
        }
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
    
    private func uploadProfileImageToFirebase() {
        guard var newUserRecord = repoManager.userRecord else {
            NSLog("LOG: ImageBottomSheetViewController-uploadProfileImageToFirebase: userRecord is not set")
            return
        }
        
        if let imageData = profileImageView?.image?.pngData() {
            newUserRecord.profileImageData = imageData
            
            DispatchQueue.main.async {
                self.repoManager.userRecord = newUserRecord
            }
            // Also need to change the local db for the changed userRecord
        }
        
        // TODO: Perform the Firebase upload logic here
        NSLog("LOG: Uploading profile image to Firebase...")
        
        // Simulate upload completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSLog("LOG: Profile image uploaded successfully to Firebase")
        }
    }
    
    // UIScrollViewDelegate method to enable zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return profileImageView
    }
}

// MARK: image picker delegate methods
extension ImageBottomSheetViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            // Log original image size
            
            // Update the userRecord profile image with the resized image
            if var userRecord = repoManager.userRecord {
                
                // Resize the image if necessary
                var finalImage = selectedImage
                if selectedImage.size.width > maxImageSize.width || selectedImage.size.height > maxImageSize.height {
                    if let resizedImage = resizeImage(selectedImage, targetSize: maxImageSize) {
                        finalImage = resizedImage
                    } else {
                        NSLog("LOG: Error resizing image")
                        return
                    }
                }
                
                // Set profileImageData with resized image
                userRecord.profileImageData = finalImage.jpegData(compressionQuality: 0.8)
                
                if let imageData = finalImage.jpegData(compressionQuality: 0.8) {
                    // Update the repoManager's userRecord on the main thread
                    self.updateProfileImage(imageData: imageData)  // Refresh the image in the bottom sheet
                    self.isImageSelected = true  // Mark that an image has been selected
                    self.changeButton.setTitle("프로필 사진으로 사용", for: .normal)  // Change button text
                }
            }
        }
        // Dismiss only the image picker, not the bottom sheet
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss only the image picker, not the bottom sheet
        picker.dismiss(animated: true, completion: nil)
    }
}
