import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel = HomeViewModel.shared
    @State private var isTextFieldFocused = false

    // For rainbow background
    @State private var hue: Double = 0.0
    @State private var colors: [Color] = [
        Color(hue: 0.0, saturation: 1, brightness: 1),
        Color(hue: 0.1, saturation: 1, brightness: 1)
    ]

    var body: some View {
        VStack {
            if isTextFieldFocused {
                HStack {
                     Button(action: {
                        isTextFieldFocused = false
                        UIApplication.shared.endEditing()
                    }) {
                        Text("Cancel")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor(white: 0.6, alpha: 1.0)))
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .transition(.opacity)
                    Spacer()
                }
            }

            VStack {
                Text("add by #pin")
                    .font(.title2)
                    .fontWeight(.bold)
                    .animation(.spring(response: 0.5, dampingFraction: 0.4, blendDuration: 0.1), value: isTextFieldFocused) // Bouncy effect

                Text(isTextFieldFocused ? "enter your friend's pin" : "ask your friend for their pin")
                    .font(.title3)
                    .foregroundColor(Color(UIColor(white: 0.5, alpha: 1.0)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1), value: isTextFieldFocused) // Bouncy effect
                
            }
            .padding(.bottom, 10)

            HStack {
                Text("#")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor(white: 0.6, alpha: 1.0)))
                TextField("", text: Binding(
                    get: {
                        viewModel.friendPin
                    },
                    set: { newValue in
                        if newValue.count <= 7 {
                            viewModel.friendPin = newValue
                        }
                    }
                ), onEditingChanged: { isEditing in
                    // Update the focus state based on whether the TextField is being edited
                    isTextFieldFocused = isEditing
                })
                .autocapitalization(.none)
                .font(.largeTitle)
                .accentColor(.white)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Paste from clipboard button
            if isTextFieldFocused && viewModel.friendPin.count == 0 {
                Button(action: {
                    if let clipboardContent = UIPasteboard.general.string {
                        viewModel.friendPin = clipboardContent
                    }
                }) {
                    Text("Paste from clipboard")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .padding(.horizontal)
                        .background(
                            SpeechBubbleShape()
                                .fill(Color(.secondarySystemBackground))
                                .offset(y: -5)
                        )
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isTextFieldFocused)
            }
            
            if isTextFieldFocused {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        viewModel.friendPin = viewModel.friendPin.lowercased()
                        viewModel.addFriend()
                    }) {
                        ZStack {
                            // Background conditional rendering
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
                        .frame(width: 50, height: 50)
                    }
                    .onAppear {
                        startHueRotation()
                    }
                    
                    Spacer()
                        .frame(width: 20)
                }
                .padding(.top, 20)
            }

            Spacer()
        }
//        .border(.green)
    }
    
    private func startHueRotation() {
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
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

extension UIApplication {
    func endEditing(_ force: Bool = false) {
        let keyWindow = connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
        keyWindow?.endEditing(force)
    }
}
