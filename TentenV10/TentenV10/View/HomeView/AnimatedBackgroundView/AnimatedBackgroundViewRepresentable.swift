import SwiftUI

struct AnimatedBackgroundViewRepresentable: UIViewRepresentable {
    var image: UIImage?

    func makeUIView(context: Context) -> AnimatedBackgroundView {
        return AnimatedBackgroundView()
    }

    func updateUIView(_ uiView: AnimatedBackgroundView, context: Context) {
        uiView.setImage(image)
    }
}
