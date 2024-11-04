import SwiftUI
import UIKit

struct ImagePickerViewRepresentable: UIViewControllerRepresentable {
    var onNext: () -> Void
    
    func makeUIViewController(context: Context) -> ImagePickerViewController {
//        return ImagePickerViewController() // Directly return the new view controller
        let viewController = ImagePickerViewController()
        viewController.onNext = onNext // Set onNext in the view controller
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ImagePickerViewController, context: Context) {
        // No updates needed
    }
}
