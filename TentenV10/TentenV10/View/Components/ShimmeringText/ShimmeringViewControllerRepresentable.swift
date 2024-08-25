import SwiftUI

struct ShimmeringViewControllerRepresentable: UIViewControllerRepresentable {
    var text: String
    var font: UIFont
    var fontSize: CGFloat
    
    func makeUIViewController(context: Context) -> ShimmeringViewController {
        let viewController = ShimmeringViewController()
        viewController.configure(with: text, font: font, fontSize: fontSize)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ShimmeringViewController, context: Context) {
        // Update the view controller if needed
    }
}
