import SwiftUI

struct PermissionButton: View {
    @State private var hue: Double = 0.0
    @State private var colors: [Color] = [
        Color(hue: 0.0, saturation: 1, brightness: 1),
        Color(hue: 0.1, saturation: 1, brightness: 1)
    ]
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var action: () -> Void
    
    var body: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            action() // Execute the passed action
        }) {
            ZStack {
                LinearGradient(gradient: Gradient(colors: colors), startPoint: .trailing, endPoint: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Text("Continue")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(20)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
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
    PermissionButton(action: {
        print("Continue button pressed")
    })
    .preferredColorScheme(.dark)
}
