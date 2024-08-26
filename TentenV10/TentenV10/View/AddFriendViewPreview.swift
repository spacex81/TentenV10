import SwiftUI

struct AddFriendViewPreview: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    @State private var isTextFieldFocused = false

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
                TextField("", text: $viewModel.friendPin, onEditingChanged: { isEditing in
                    // Update the focus state based on whether the TextField is being edited
                    isTextFieldFocused = isEditing
                })
                .autocapitalization(.none)
                // TODO: remove auto recommend
                .font(.largeTitle)
                .accentColor(.white)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Paste from clipboard button
            if isTextFieldFocused {
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

            if viewModel.friendPin.count > 0 {
                Button(action: {
                    viewModel.friendPin = viewModel.friendPin.lowercased()
                    viewModel.addFriend()
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
//        .border(.green)
    }
}

struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius: CGFloat = 10
        let triangleHeight: CGFloat = 10
        let triangleWidth: CGFloat = 20
        
        // Draw the rounded rectangle
        path.addRoundedRect(in: CGRect(
            x: rect.minX,
            y: rect.minY + triangleHeight, // Move the rectangle down to make space for the triangle
            width: rect.width,
            height: rect.height - triangleHeight
        ), cornerSize: CGSize(width: radius, height: radius))
        
        // Draw the triangle (speech bubble tail)
        let trianglePath = Path { p in
            p.move(to: CGPoint(x: rect.midX - triangleWidth / 2, y: rect.minY + triangleHeight))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX + triangleWidth / 2, y: rect.minY + triangleHeight))
            p.closeSubpath()
        }
        
        path.addPath(trianglePath)
        
        return path
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


#Preview {
    AddFriendViewPreview()
        .preferredColorScheme(.dark)
}
