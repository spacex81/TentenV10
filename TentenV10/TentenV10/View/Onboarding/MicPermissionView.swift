import SwiftUI
import AVFoundation

struct MicPermissionView: View {
    @State private var showSettingsView = false
    @Environment(\.scenePhase) var scenePhase // Observe the scene phase

    var onNext: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("마이크 접근을 허용해주세요")
                        .font(.title)
                    Text("친구와 대화할 때 마이크를 사용해요!")
                        .font(.headline)
                }
                .padding(.vertical, 50)
                
                // Permission button to request mic permission
                PermissionButton(action: requestMicrophonePermission)
            }
            .fullScreenCover(isPresented: $showSettingsView) {
                SettingsView2(onSettingsReturn: {
                    Task {
                        await AuthViewModel.shared.checkPermissions() // Recheck permissions when returning from settings
                    }
                })
                .transition(.move(edge: .trailing)) // Slide in from the right
                .animation(.easeInOut, value: showSettingsView) // Add animation
            }
            // Detect when the app comes back to the foreground
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    if newPhase == .active {
                        NSLog("LOG: App returned to foreground")
                        await AuthViewModel.shared.checkPermissions() // Recheck permissions

                        if showSettingsView && AuthViewModel.shared.isMicPermissionGranted {
                            // Dismiss SettingsView when microphone permission is granted
                            showSettingsView = false
                        }
                    }
                }
            }
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
                    DispatchQueue.main.async {
                        showSettingsView = true // Show settings view if permission is denied
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted.")
                    onNext()
                } else {
                    print("Microphone permission denied.")
                    DispatchQueue.main.async {
                        showSettingsView = true // Show settings view if permission is denied
                    }
                }
            }
        }
    }
}

// MARK: Seems unnecessary to maintain another SettingsView. Will refactor later
// Settings View for guiding the user to manually enable permissions in the app settings
//struct SettingsView2: View {
//    var onSettingsReturn: () -> Void
//
//    var body: some View {
//        VStack {
//            // MARK: Title
//            Text("마이크 권한을 설정에서 켜주세요")
//                .font(.title)
//                .fontWeight(.bold)
//                .padding(.bottom, 5)
//            
//            // MARK: Subtext
//            Text("마이크 허용 없이는 친구들과 대화가 어려워요 😢")
//
//            Button(action: openSettings) {
//                Text("설정으로 가기")
//                    .font(.headline)
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//        }
//        .onAppear {
//            // When the user comes back from settings, recheck permissions
//            onSettingsReturn()
//        }
//    }
//
//    // Function to open the settings app
//    private func openSettings() {
//        if let url = URL(string: UIApplication.openSettingsURLString) {
//            if UIApplication.shared.canOpenURL(url) {
//                UIApplication.shared.open(url)
//            }
//        }
//    }
//}

struct SettingsView2: View {
    var onSettingsReturn: () -> Void

    var body: some View {
        VStack {
            // MARK: Title
            Text("마이크 권한을 설정에서 켜주세요")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            // MARK: Subtext
            Text("마이크 허용 없이는 친구들과 대화가 어려워요 😢")

            Button(action: openSettings) {
                Text("설정으로 가기")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            // When the user comes back from settings, recheck permissions
            onSettingsReturn()
        }
    }

    // Function to open the settings app and dismiss the keyboard
    private func openSettings() {
        dismissKeyboard() // Dismiss the keyboard before opening settings
        
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    // Function to dismiss the keyboard globally
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


#Preview {
    MicPermissionView(onNext: {
        print("Next button pressed")
    })
    .preferredColorScheme(.dark)
}
