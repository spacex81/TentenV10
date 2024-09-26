import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack {
            VStack {
                Text("알림을 허용해주세요")
                    .font(.title)
                
                Text("친구가 말하고 있을 때 알려드릴게요!")
                    .font(.headline)
            }
            .padding(.vertical, 50)
            
            // Use PermissionButton with notification permission request action
            PermissionButton(action: requestNotificationPermission)
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
