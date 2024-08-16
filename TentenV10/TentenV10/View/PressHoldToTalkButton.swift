import SwiftUI

struct PressHoldToTalkButton: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isPressed ? Color.red : Color.green)
                .frame(width: 100, height: 100)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isPressed)

            Text(isPressed ? "Talking..." : "Hold to Talk")
                .foregroundColor(.white)
                .font(.headline)
        }
        .onLongPressGesture(minimumDuration: .infinity, pressing: { isPressing in
            isPressed = isPressing
            if isPressing {
                // Start talking: connect and publish
                Task {
                    if !viewModel.isConnected {
                        await viewModel.connect()
                    }
                    viewModel.publishAudio()
                }
            } else {
                // Stop talking: unpublish
                Task {
                    await viewModel.unpublishAudio()
                    viewModel.disconnect()
                }
            }
        }) {
            // Optional: action to perform when the gesture ends
            print("Talk ended")
        }
    }
}
