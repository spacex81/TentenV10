import SwiftUI

struct AddFriendButton: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel = HomeViewModel.shared
    
    @State private var hue: Double = 0.0
    @State private var colors: [Color] = [
        Color(hue: 0.0, saturation: 1, brightness: 1),
        Color(hue: 0.1, saturation: 1, brightness: 1)
    ]
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)


    var body: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            viewModel.friendPin = viewModel.friendPin.lowercased()
            viewModel.addFriend()
            dismiss()
        }) {
            ZStack {
                // Need to add some bouncy animation when background changes
                // Background
                if viewModel.friendPin.count < 7 {
                    Color(.secondarySystemBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .trailing, endPoint: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // Foreground image
                Image(systemName: "arrow.right")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(15)
            }
            .frame(width: 50, height: 50) // Fix size to avoid shifting
            .animation(.easeInOut(duration: 0.1), value: viewModel.friendPin.count) // Animate background change
        }
        .onAppear {
            startHueRotation()
        }
    }
    
    private func startHueRotation() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation {
                hue += 0.01
                if hue > 1.0 { hue = 0.0 }
                updateColors()
            }
        }
    }

    private func updateColors() {
        colors = [
            Color(hue: hue, saturation: 1, brightness: 1),
            Color(hue: (hue + 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 1, brightness: 1)
        ]
    }
}

#Preview {
    AddFriendButton()
        .preferredColorScheme(.dark)
}


