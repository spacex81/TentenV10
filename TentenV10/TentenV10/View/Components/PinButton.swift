import SwiftUI

struct PinButton: View {
    @State private var isPressed = false
    var pin: String
    
    init(pin: String) {
        self.pin = pin
    }
    
    var body: some View {
        ZStack {
            if isPressed {
                ConfirmationText()
                    .transition(.scale(scale: 0.1, anchor: .center).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)) {
                                isPressed = false
                            }
                        }
                    }
            } else {
                PinText(isPressed: $isPressed, pin: pin)
                    .transition(.scale(scale: 0.1, anchor: .center).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5), value: isPressed)
    }
}

struct PinText: View {
    @Binding var isPressed: Bool
    var pin: String
    
    let fontSize: CGFloat = 18 // New font size

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)) {
                isPressed.toggle()
            }
            UIPasteboard.general.string = pin
        } label: {
            let adjustedPin = "PIN: " + pin
            
            ShimmeringViewControllerRepresentable(
                text: adjustedPin,
                font: UIFont.systemFont(ofSize: fontSize, weight: .regular),
                fontSize: fontSize
            )
            .padding(3)
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor(white: 0.3, alpha: 1.0)), lineWidth: 2)
            )
            .frame(width: 130, height: 30)
        }
    }
}

struct ConfirmationText: View {
    var body: some View {
        Text("pin copied!")
            .font(.system(size: 18)) // Match the font size here as well
            .frame(width: 140, height: 30)
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            )
            .foregroundColor(.black)
    }
}

#Preview {
    PinButton(pin: "b0mf7mk")
        .preferredColorScheme(.dark)
}
