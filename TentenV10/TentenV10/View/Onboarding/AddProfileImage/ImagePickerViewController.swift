import UIKit

class ImagePickerViewController: UIViewController, UIScrollViewDelegate {
    let repoManager = RepositoryManager.shared
    
    var onNext: (() -> Void)?
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private var profileImageView: UIImageView? // Image view for profile image
    private var isImageSelected = false
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
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
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        // MARK: 'ImagePickerViewController.self' makes error
        button.addTarget(self, action: #selector(resetImage), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        setupViews()
        changeButton.startHueRotation()
    }
    
    private func setupViews() {
        // Set up scroll view and profile image view
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.clipsToBounds = true
        scrollView.addSubview(profileImageView)
        self.profileImageView = profileImageView
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            profileImageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            profileImageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        
        // Set up button stack with change and close buttons
        let buttonStack = UIStackView(arrangedSubviews: [changeButton, closeButton])
        buttonStack.axis = .vertical
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        
        view.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            buttonStack.heightAnchor.constraint(equalToConstant: 150),
            buttonStack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85)
        ])
    }
    
    private func updateProfileImage(imageData: Data) {
        guard let image = UIImage(data: imageData) else { return }
        
        profileImageView?.image = image
        scrollView.contentSize = image.size
        
        // Update the frame and content size to match the new image
        profileImageView?.frame = CGRect(origin: .zero, size: image.size)
        scrollView.zoomScale = scrollView.minimumZoomScale
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
    
    private func uploadProfileImageToFirebase() {
        guard var newUserRecord = repoManager.userRecord else {
            NSLog("LOG: ImageBottomSheetViewController-uploadProfileImageToFirebase: userRecord is not set")
            return
        }
        
        // Capture the visible portion of the image
        if let visibleImage = captureVisibleImage(), let imageData = visibleImage.pngData() {
            newUserRecord.profileImageData = imageData
            
            // Update UserRecord in memory
            DispatchQueue.main.async {
                self.repoManager.userRecord = newUserRecord
            }
            
            // Update UserRecord in local db
            repoManager.createUserInDatabase(user: newUserRecord)

            Task {
                do {
                    // Store profile image on Firebase storage and get the image URL
                    let profileImagePath = try await repoManager.saveProfileImageInFirebaseStorage(id: newUserRecord.id, profileImageData: newUserRecord.profileImageData!)
                    
                    // Store profile image path and imageOffset to Firebase Firestore
                    let fieldsToUpdate: [String: Any] = [
                        "profileImagePath": profileImagePath
                    ]
                    repoManager.updateUserField(userId: newUserRecord.id, fieldsToUpdate: fieldsToUpdate)
                    
                    NSLog("LOG: Profile image path successfully updated in Firestore")
                } catch {
                    NSLog("LOG: Error storing new profile image: \(error.localizedDescription)")
                }
            }
        }
        
        NSLog("LOG: Uploading profile image to Firebase...")
        
        onNext?()
    }
    
    private func captureVisibleImage() -> UIImage? {
        // Make sure there is an image to work with
        guard let image = profileImageView?.image else {
            return nil
        }
        
        // Get the size of the image in the image view's coordinate system
        let imageSize = image.size
        let imageViewSize = profileImageView?.bounds.size ?? CGSize.zero
        
        // Calculate the ratio between the image size and the imageView size
        let widthScale = imageSize.width / imageViewSize.width
        let heightScale = imageSize.height / imageViewSize.height

        // Get the visible rect from the scroll view
        let visibleRect = CGRect(x: scrollView.contentOffset.x,
                                 y: scrollView.contentOffset.y,
                                 width: scrollView.bounds.width,
                                 height: scrollView.bounds.height)

        // Convert the visible rect to the image's coordinate system, accounting for zoom scale
        let imageRect = CGRect(
            x: visibleRect.origin.x * widthScale / scrollView.zoomScale,
            y: visibleRect.origin.y * heightScale / scrollView.zoomScale,
            width: visibleRect.width * widthScale / scrollView.zoomScale,
            height: visibleRect.height * heightScale / scrollView.zoomScale
        )
        
        // Ensure the imageRect is within the image bounds
        let cropRect = CGRect(
            x: max(0, imageRect.origin.x),
            y: max(0, imageRect.origin.y),
            width: min(imageSize.width, imageRect.width),
            height: min(imageSize.height, imageRect.height)
        )

        // Render the visible portion of the image to a new UIImage
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        let croppedImage = UIImage(cgImage: cgImage)
        
        return croppedImage
    }


    
    @objc private func resetImage() {
        // Reset the profile image view
        profileImageView?.image = nil
        // Reset the zoom scale
        scrollView.zoomScale = scrollView.minimumZoomScale
        // Update the button title
        changeButton.setTitle("사진 선택하기", for: .normal)
        isImageSelected = false
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return profileImageView
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            if var userRecord = repoManager.userRecord {
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
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
