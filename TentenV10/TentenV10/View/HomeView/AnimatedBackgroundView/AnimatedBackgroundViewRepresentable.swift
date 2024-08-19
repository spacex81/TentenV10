import SwiftUI

struct AnimatedBackgroundViewRepresentable: UIViewRepresentable {
    var image: UIImage?
    @Binding var isPressing: Bool
    @Binding var isPublished: Bool

    func makeUIView(context: Context) -> AnimatedBackgroundView {
        return AnimatedBackgroundView()
    }

    func updateUIView(_ uiView: AnimatedBackgroundView, context: Context) {
        uiView.setImage(image)
    }
}
