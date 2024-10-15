import SwiftUI

struct MainRingView: View {
    let strokeSize: CGFloat
    @ObservedObject var viewModel = HomeViewModel.shared

    
    // RGB color for the green circle
    let greenColor = Color(red: 170 / 255, green: 251 / 255, blue: 105 / 255)
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Main ring with a 10% gap
            Circle()
                .trim(from: 0.1, to: 1.0)  // 10% gap
                .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-75))  // Shift the empty part to upper-right
                .opacity(1.0)
                .frame(width: strokeSize, height: strokeSize)
            
            if viewModel.selectedFriend?.status == "foreground" || viewModel.selectedFriend?.status == "background" {
                Circle()
                    .fill(greenColor)
                    .frame(width: strokeSize * 0.15, height: strokeSize * 0.15)  // Size of the green circle
                    .offset(x: strokeSize * 0.26, y: -strokeSize * 0.41)  // Position the circle at the gap
                    .shadow(color: greenColor.opacity(0.8), radius: 10, x: 0, y: 0)  // Glow effect
                    .scaleEffect(isAnimating ? 1.01 : 0.99)  // Animate scale (vibration effect)
                    .onAppear {
                        // Add animation to scale effect only
                        withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
            }
        }
    }
}

#Preview {
    MainRingView(strokeSize: 100)
        .preferredColorScheme(.dark)
}
