import SwiftUI

struct AddUsernameButton: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    private let repoManager = RepositoryManager.shared
    
    @State private var hue: Double = 0.0
    @State private var colors: [Color] = [
        Color(hue: 0.0, saturation: 1, brightness: 1),
        Color(hue: 0.1, saturation: 1, brightness: 1)
    ]
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var onComplete: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            
            impactFeedback.impactOccurred()
            
            if viewModel.username.count > 0 {
                guard let userRecord = viewModel.userRecord else {
                    NSLog("LOG: UserRecord is nil when trying to add username in onboarding")
                    return
                }
                
                // Add username to local database
                repoManager.createUserInDatabase(user: userRecord)
                
                NSLog("LOG: new username: \(userRecord.username)")
                // Add username to remote firebase
                repoManager.updateUserField(userId: userRecord.id, fieldsToUpdate: ["username": userRecord.username])
                NSLog("LOG: Username successfully updated in Firebase")
                
                if let onComplete = onComplete {
                    onComplete()
                }
            }
        }) {
            ZStack {
                // Need to add some bouncy animation when background changes
                // Background
                if viewModel.username.count < 1 {
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
            .animation(.easeInOut(duration: 0.1), value: viewModel.username.count) // Animate background change
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
    AddUsernameButton()
        .preferredColorScheme(.dark)
}


