import SwiftUI

struct HoldToReplyBubble: View {
    @State private var verticalOffset: CGFloat = 0

    var body: some View {
        VStack {
            Spacer()
            
            // Container view for both text and speech bubble
            VStack {
                Text("hold to reply")
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
            }
            .offset(y: verticalOffset) // Apply vertical offset to the whole view
            .onAppear {
                // Start the animation when the view appears
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    verticalOffset = 5 // Adjust the amplitude of the bounce here
                }
            }

            Spacer()
        }
    }
}


#Preview {
    HoldToReplyBubble()
        .preferredColorScheme(.dark)
}
