import SwiftUI

// FloatingEffect ViewModifier to handle floating animation
struct FloatingEffect: ViewModifier {
    @State private var verticalOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: verticalOffset)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    verticalOffset = -5 // Start the bounce animation
                }
            }
    }
}

// Convenience extension for applying the floating effect
extension View {
    func floating() -> some View {
        self.modifier(FloatingEffect())
    }
}

struct HoldToTalkBubble: View {
    @State private var verticalOffset: CGFloat = 0
    @ObservedObject var viewModel = HomeViewModel.shared
    @State private var showForegroundText = false // State to control the text transition
    
    var body: some View {
        VStack {
            Spacer()
            
            // Container view for both text and speech bubble
            ZStack {
                // "눌러서 말하기" text (Default)
                if !showForegroundText {
                    Text(NSLocalizedString("hold to talk", comment: ""))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .background(
                            SpeechBubbleShapeDownward()
                                .fill(Color(.white))
                                .stroke(Color.white, lineWidth: 2)
                                .offset(y: 5)
                        )
                        .scaleEffect(showForegroundText ? 0.7 : 1.0)  // Scale down when transitioning out
                        .transition(.scale)  // Apply scale transition
                        .onAppear {
//                            print("Displaying: 눌러서 말하기")
                        }
                        .floating() // Apply floating animation
                }
                
                // "👀 여기 있어요" text (Friend is foreground)
                if showForegroundText {
                    Text("👀 여기 있어요")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding()
                        .background(
                            SpeechBubbleShapeDownward()
                                .fill(Color(.white))
                                .stroke(Color.white, lineWidth: 2)
                                .offset(y: 5)
                        )
                        .scaleEffect(showForegroundText ? 1.0 : 0.7)  // Scale up with bounce effect
                        .transition(.scale)  // Apply scale transition
                        .animation(.interpolatingSpring(stiffness: 200, damping: 15), value: showForegroundText)  // Spring bounce effect
                        .onAppear {
//                            print("Displaying: 👀 여기 있어요")
                        }
                        .floating() // Apply floating animation
                }
            }
            .onAppear {
                updateTextTransitionOnAppear()
            }
            .onChange(of: viewModel.friendStatuses) { _, newValue in
                updateTextTransition()
            }
            .onChange(of: viewModel.selectedFriend) { _, _ in
                updateTextTransition()
            }
            .onDisappear {
//                print("HoldToTalkBubble disappeared")
            }

            Spacer()
        }
    }
    
    private func updateTextTransitionOnAppear() {
        if let id = viewModel.selectedFriend?.id {
            let appStatus = viewModel.friendStatuses[id]
            NSLog("LOG: updateTextTransition-appStatus: \(String(describing: appStatus))")
            if appStatus == "foreground" {
                showForegroundText = true
            } else {
                showForegroundText = false
            }
        }
    }
    
    private func updateTextTransition() {
//        print("LOG: Updating text transition")
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {  // Bouncy animation for scale transition
            if let id = viewModel.selectedFriend?.id {
                let appStatus = viewModel.friendStatuses[id]
                NSLog("LOG: updateTextTransition-appStatus: \(String(describing: appStatus))")
                if appStatus == "foreground" {
                    showForegroundText = true
                } else {
                    showForegroundText = false
                }
            }
        }
    }
}


#Preview {
    HoldToTalkBubble()
        .preferredColorScheme(.dark)
}
