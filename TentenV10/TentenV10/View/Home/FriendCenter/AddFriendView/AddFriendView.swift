import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel = HomeViewModel.shared
    @State private var isTextFieldFocused = false

    var body: some View {
        VStack {
            if isTextFieldFocused {
                HStack {
                     Button(action: {
                        isTextFieldFocused = false
                        viewModel.friendPin = ""
                        UIApplication.shared.endEditing()
                    }) {
                        Text("Cancel")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor(white: 0.6, alpha: 1.0)))
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .padding(.top, 30)
                            .padding(.leading, 30)
                    }
                    .transition(.opacity)
                    Spacer()
                }
            }
            
            VStack {
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
                    .autocorrectionDisabled(true)
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
                                SpeechBubbleShapeUpward()
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
                        InviteFriendButton()
                        
                        Spacer()
                            .frame(width: 20)
                    }
                    .padding(.top, 20)
                }

                Spacer()
            }
            .padding(20)
        }
//        .border(.green)
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
