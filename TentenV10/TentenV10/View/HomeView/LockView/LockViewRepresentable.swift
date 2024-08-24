import SwiftUI

struct LockViewRepresentable: UIViewRepresentable {
    
    var isLocked: Bool
    var progress: Float
//    var onLockedIconZoomAnimationCompletion: () -> Void
    
    func makeUIView(context: Context) -> LockView {
        let lockView = LockView()
        return lockView
    }
    
    func updateUIView(_ uiView: LockView, context: Context) {
        uiView.isLocked = isLocked
        uiView.progress = progress
        
    }
}
