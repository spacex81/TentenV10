import SwiftUI

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
                    Text("눌러서 말하기")
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
                }
            }
            .offset(y: verticalOffset) // Apply vertical offset to the whole view
            .onAppear {
                // Start the bounce animation for the whole view
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    verticalOffset = 5 // Adjust the amplitude of the bounce here
                }
                updateTextTransition() // Check and update the text transition on appear
            }
            .onChange(of: viewModel.selectedFriend?.status) { _ in
                updateTextTransition() // Update the text transition when status changes
            }

            Spacer()
        }
    }
    
    private func updateTextTransition() {
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 15)) {  // Bouncy animation for scale transition
            if viewModel.selectedFriend?.status == "foreground" {
                showForegroundText = true
            } else {
                showForegroundText = false
            }
        }
    }
}


#Preview {
    HoldToTalkBubble()
        .preferredColorScheme(.dark)
}
