import SwiftUI
import AVFoundation

struct MicPermissionView: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack {
            Text("마이크 접근을 허용해주세요")
                .font(.title)
                .padding()
            
            Text("친구와 대화할 때 마이크를 사용해요!")
                .font(.headline)
                .padding()
            
            // Button to request microphone permission
            Button(action: requestMicrophonePermission) {
                Text("계속")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding()
        }
    }
    
    // Function to request microphone permission
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted.")
                    onNext()
                } else {
                    print("Microphone permission denied.")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted.")
                    onNext()
                } else {
                    print("Microphone permission denied.")
                }
            }
        }
        
    }
}

#Preview {
    MicPermissionView(onNext: {
        print("Next button pressed")
    })
        .preferredColorScheme(.dark)
}
