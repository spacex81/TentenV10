import SwiftUI

// TODO: decrease the font sie
// also I don't want using font size as number '22' and 'title3' at the same time
// let's just use number
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
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)) {
                isPressed.toggle()
            }
            UIPasteboard.general.string = pin
        } label: {
            ZStack {
                HStack {
                    Text(" PIN:")
                        .font(.title3)
                        .foregroundColor(Color(UIColor(white: 0.7, alpha: 1.0)))
                    
                    ShimmeringViewControllerRepresentable(
                        text: pin,
                        font: UIFont.systemFont(ofSize: 22, weight: .regular),
                        fontSize: 22
                    )
                    .onAppear {
                        // Log to ensure it appears and animation is added
                        print("PinText appears, configure shimmering effect.")
                    }
                    .offset(x: -5, y: 12)
                }
            }
            .frame(width: 140, height: 30)
            .padding(3)
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(UIColor(white: 0.3, alpha: 1.0)), lineWidth: 2)
            )
        }
    }
}

struct ConfirmationText: View {
    var body: some View {
        Text("pin copied!")
            .font(.title3)
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
    PinButton(pin: "2frna4m")
        .preferredColorScheme(.dark)
}
