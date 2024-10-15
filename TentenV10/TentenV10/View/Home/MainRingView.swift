import SwiftUI

//struct MainRingView: View {
//    let strokeSize: CGFloat
//    @ObservedObject var viewModel = HomeViewModel.shared
//
//    // RGB color for the green circle
//    let greenColor = Color(red: 170 / 255, green: 251 / 255, blue: 105 / 255)
//    
//    @State private var isAnimating = false
//    @State private var isVisible = false
//    
//    var body: some View {
//        ZStack {
//            // Main ring with a 10% gap
//            Circle()
//                .trim(from: 0.1, to: 1.0)  // 10% gap
//                .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
//                .rotationEffect(.degrees(-75))  // Shift the empty part to upper-right
//                .opacity(1.0)
//                .frame(width: strokeSize, height: strokeSize)
//            
//            // Green circle that appears/disappears with animation
//            Circle()
//                .fill(greenColor)
//                .frame(width: strokeSize * 0.15, height: strokeSize * 0.15)  // Size of the green circle
//                .offset(x: strokeSize * 0.26, y: -strokeSize * 0.41)  // Position the circle at the gap
//                .shadow(color: greenColor.opacity(0.8), radius: 10, x: 0, y: 0)  // Glow effect
//                .scaleEffect(isAnimating ? 1.01 : 0.99)  // Animate scale (vibration effect)
//                .opacity(isVisible ? 1 : 0)  // Fade-in and fade-out effect based on visibility
//                .animation(.easeInOut(duration: 0.3), value: isVisible)  // Smooth opacity transition
//                .onAppear {
//                    // Add pulse animation when the green circle appears
//                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
//                        isAnimating = true
//                    }
//                }
//        }
//        .onAppear {
//            // Check the friend's status and decide if the green circle should be visible
//            updateVisibilityBasedOnStatus()
//        }
//        .onChange(of: viewModel.selectedFriend?.status) { _, _ in
//            // Update visibility based on status change
//            updateVisibilityBasedOnStatus()
//        }
//    }
//
//    // Function to handle visibility of the green circle based on friend's status
//    private func updateVisibilityBasedOnStatus() {
//        if viewModel.selectedFriend?.status == "foreground" || viewModel.selectedFriend?.status == "background" {
//            isVisible = true
//        } else {
//            isVisible = false
//        }
//    }
//}
//
//#Preview {
//    MainRingView(strokeSize: 100)
//        .preferredColorScheme(.dark)
//}

struct MainRingView: View {
    let strokeSize: CGFloat
    @ObservedObject var viewModel = HomeViewModel.shared

    // RGB color for the green circle
    let greenColor = Color(red: 170 / 255, green: 251 / 255, blue: 105 / 255)
    
    @State private var isAnimating = false
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            // Main ring with a 10% gap
            Circle()
                .trim(from: 0.1, to: 1.0)  // 10% gap
                .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-75))  // Shift the empty part to upper-right
                .opacity(1.0)
                .frame(width: strokeSize, height: strokeSize)
            
            // Green circle that appears/disappears with animation
            Circle()
                .fill(greenColor)
                .frame(width: strokeSize * 0.15, height: strokeSize * 0.15)  // Size of the green circle
                .offset(x: strokeSize * 0.26, y: -strokeSize * 0.41)  // Position the circle at the gap
                .shadow(color: greenColor.opacity(0.8), radius: 10, x: 0, y: 0)  // Glow effect
                .scaleEffect(isAnimating ? 1.01 : 0.99)  // Animate scale (vibration effect)
                .opacity(isVisible ? 1 : 0)  // Fade-in and fade-out effect based on visibility
                .scaleEffect(isVisible ? 1 : 0.6)  // Additional scaling for a bouncy effect
                .animation(.interpolatingSpring(stiffness: 100, damping: 10), value: isVisible)  // Bouncy spring animation
                .onAppear {
                    // Add pulse animation when the green circle appears
                    withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
        }
        .onAppear {
            // Check the friend's status and decide if the green circle should be visible
            updateVisibilityBasedOnStatus()
        }
        .onChange(of: viewModel.selectedFriend?.status) { _, _ in
            // Update visibility based on status change
            updateVisibilityBasedOnStatus()
        }
    }

    // Function to handle visibility of the green circle based on friend's status
    private func updateVisibilityBasedOnStatus() {
        if viewModel.selectedFriend?.status == "foreground" || viewModel.selectedFriend?.status == "background" {
            isVisible = true
        } else {
            isVisible = false
        }
    }
}

#Preview {
    MainRingView(strokeSize: 100)
        .preferredColorScheme(.dark)
}
