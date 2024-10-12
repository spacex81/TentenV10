import UIKit

final class ImageBottomSheetViewController: UIViewController {
    
    var onDismiss: (() -> Void)?

    let repoManager = RepositoryManager.shared
    // TODO: use 'repoManager.userRecord' (type is 'UserRecord?') to set the background image of this bottom sheet
    
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
    
    private let changeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("사진 바꾸기", for: .normal)
        button.setTitleColor(.red, for: .normal)
        // Change this from 'BottomSheetViewController.self' to 'self'
        button.addTarget(nil, action: #selector(changeImageAction), for: .touchUpInside)
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        // Change this from 'BottomSheetViewController.self' to 'self'
        button.addTarget(nil, action: #selector(dismissBottomSheet), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("ImageSheetViewController-viewDidLoad")
        
        setupViews()
        setupGesture()
    }
    
    private func setupViews() {
        view.addSubview(dimmingView)
        view.addSubview(contentView)
        
        dimmingView.frame = view.bounds
        
        // Get the profile image from the userRecord and set it as the background
        if let imageData = repoManager.userRecord?.profileImageData, let profileImage = UIImage(data: imageData) {
//            NSLog("LOG: ImageBottomSheet-setupViews: imageData available")
            
            let imageView = UIImageView(image: profileImage)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            contentView.insertSubview(imageView, at: 0) // Add image view at the back

            // Use Auto Layout for imageView
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        } else {
//            NSLog("LOG: ImageBottomSheet-setupViews: imageData not available")
            contentView.backgroundColor = .systemGray // Fallback color
        }
        
        let height = view.frame.height * 1.0 // Adjust this as per the height you want
        contentView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        // Create a vertical stack for buttons
        let buttonStack = UIStackView(arrangedSubviews: [changeButton, closeButton])
        buttonStack.axis = .vertical
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        
        // Add stack view to contentView
        contentView.addSubview(buttonStack)
        
        // Set up constraints for the button stack
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            buttonStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 100),
            buttonStack.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8)
        ])
        
        // Animate bottom sheet presentation
        UIView.animate(withDuration: 0.3) {
            self.contentView.frame.origin.y = self.view.frame.height - height
            self.dimmingView.alpha = 1
        }
    }

    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissBottomSheet))
        dimmingView.addGestureRecognizer(tapGesture)
        
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
//        contentView.addGestureRecognizer(panGesture)
    }
    
    
    @objc private func changeImageAction() {

        
        self.dismissBottomSheet()
    }
    
    @objc private func dismissBottomSheet() {
        // Animate only the bottom sheet's dismissal without affecting the ProfileView
        UIView.animate(withDuration: 0.3, animations: {
            self.contentView.frame.origin.y = self.view.frame.height  // Move bottom sheet off screen
            self.dimmingView.alpha = 0  // Fade out the dimming view
        }) { _ in
            // Instead of dismissing the entire ProfileView, simply remove the bottom sheet's view
            self.contentView.removeFromSuperview()
            self.dimmingView.removeFromSuperview()
            self.onDismiss?()
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 { // Drag down only
                contentView.frame.origin.y += translation.y
                gesture.setTranslation(.zero, in: contentView)
            }
        case .ended:
            let threshold: CGFloat = 1000
            if contentView.frame.origin.y > view.frame.height - threshold {
                dismissBottomSheet()
            } else {
                // Snap back to original position
                UIView.animate(withDuration: 0.3) {
                    self.contentView.frame.origin.y = self.view.frame.height * 0.6
                }
            }
        default:
            break
        }
    }
}
