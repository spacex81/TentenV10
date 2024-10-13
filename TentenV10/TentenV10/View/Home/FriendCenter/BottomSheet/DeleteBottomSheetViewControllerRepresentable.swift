import SwiftUI
import UIKit

struct DeleteBottomSheetViewControllerRepresentable: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool {
        didSet {
            NSLog("LOG: DeleteBottomSheetViewControllerRepresentable-isPresented: \(isPresented)")
        }
    }
    @Binding var friendToDelete: FriendRecord?
    
    class Coordinator: NSObject, UIViewControllerTransitioningDelegate {
        var parent: DeleteBottomSheetViewControllerRepresentable
        
        init(parent: DeleteBottomSheetViewControllerRepresentable) {
            self.parent = parent
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.isPresented = false
        }
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        
        if isPresented {
            let bottomSheetVC = DeleteBottomSheetViewController()
            bottomSheetVC.modalPresentationStyle = .overFullScreen
            bottomSheetVC.friendToDelete = friendToDelete
            bottomSheetVC.onDismiss = {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
            }
            viewController.present(bottomSheetVC, animated: true, completion: nil)
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let bottomSheetVC = DeleteBottomSheetViewController()
            bottomSheetVC.modalPresentationStyle = .overFullScreen
            bottomSheetVC.friendToDelete = friendToDelete
            bottomSheetVC.onDismiss = {
                DispatchQueue.main.async {
                    self.isPresented = false
                }
            }
            uiViewController.present(bottomSheetVC, animated: true, completion: nil)
        } else {
            uiViewController.dismiss(animated: true, completion: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
}
