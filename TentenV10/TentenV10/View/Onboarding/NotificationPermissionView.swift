import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @State private var showSettingsView = false
    @Environment(\.scenePhase) var scenePhase // Observe the scene phase
    
    var onNext: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Text("알림을 허용해주세요")
                        .font(.title)
                    Text("친구가 말하고 있을 때 알려드릴게요!")
                        .font(.headline)
                }
                .padding(.vertical, 50)
                
                // Permission button
                PermissionButton(action: requestNotificationPermission)
            }
            .fullScreenCover(isPresented: $showSettingsView) {
                SettingsView(onSettingsReturn: {
                    Task {
                        await AuthViewModel.shared.checkPermissions()
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
                        
                        if showSettingsView && AuthViewModel.shared.isNotificationPermissionGranted {
                            // Set showSettingsView to false to dismiss the SettingsView
                            showSettingsView = false
                        }
                    }
                }
            }
        }
    }
    
    // Function to request notification permission
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                onNext()
            } else {
                print("Notification permission denied.")
                DispatchQueue.main.async {
                    showSettingsView = true
                }
            }
        }
    }
}

// Settings View to guide the user to manually enable notifications
struct SettingsView: View {
    var onSettingsReturn: () -> Void
    
    var body: some View {
        VStack {
            // MARK: Title
            Text("알림을 설정에서 켜주세요")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            // MARK: Subtext
            Text("알림 허용 없이는 앱 경험이 끔찍해져요...😭")

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
            // When the user comes back from settings, check permissions
            onSettingsReturn()
        }
    }
    
    // Function to open the settings app
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    NotificationPermissionView(onNext: {
        print("Next button pressed")
    })
    .preferredColorScheme(.dark)
}
