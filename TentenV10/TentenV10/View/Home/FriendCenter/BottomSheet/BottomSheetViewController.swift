import UIKit

final class BottomSheetViewController: UIViewController {
    
    var onDismiss: (() -> Void)?
    var friendToDelete: FriendRecord?
    
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
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete Friend", for: .normal)
        button.setTitleColor(.red, for: .normal)
        // Change this from 'BottomSheetViewController.self' to 'self'
        button.addTarget(nil, action: #selector(deleteFriendAction), for: .touchUpInside)
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        // Change this from 'BottomSheetViewController.self' to 'self'
        button.addTarget(nil, action: #selector(dismissBottomSheet), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        print("BottomSheetViewController-viewDidLoad")
//        print(friendToDelete ?? "friendToDelete is nil")
        
        setupViews()
        setupGesture()
    }
    
    private func setupViews() {
        view.addSubview(dimmingView)
        view.addSubview(contentView)
        
        dimmingView.frame = view.bounds
        
        let height = view.frame.height * 0.4 // 40% of screen height
        contentView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        // Create a horizontal stack for buttons
        let buttonStack = UIStackView(arrangedSubviews: [deleteButton, closeButton])
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
            buttonStack.heightAnchor.constraint(equalToConstant: 50),
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
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        contentView.addGestureRecognizer(panGesture)
    }
    
    
    @objc private func deleteFriendAction() {
        // Create a UIAlertController for confirmation
        let alertController = UIAlertController(
            title: "Confirm Deletion",
            message: "Are you sure you want to delete this friend?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            if let friendToDelete = self.friendToDelete {
                // 1) Delete friend
                self.repoManager.deleteFriend(friendId: friendToDelete.id)
                // 2-1) If we have friends left, than update the selectedFriend
                if self.repoManager.detailedFriends.count > 0 {
                    self.repoManager.selectedFriend = self.repoManager.detailedFriends[0]
                } else {
                // 2-2) If we no longer have friends, move to 'AddView'
                    self.repoManager.selectedFriend = nil
                    // TODO: Move to AddView
                    ContentViewModel.shared.onboardingStep = .addFriend
                }
                // TODO: Also notifiy your friend to delete
            } else {
                print("ERROR: friendToDelete is nil when trying to delete friend in bottom sheet view controller")
            }
            self.dismissBottomSheet() // Close the bottom sheet after deleting
        }
        
        // Add a "Cancel" action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Add actions to the alert controller
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
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
