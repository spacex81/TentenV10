import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack {
            Text("알림을 허용해주세요")
                .font(.title)
                .padding()
            
            Text("친구가 말하고 있을 때 알려드릴게요!")
                .font(.headline)
                .padding()
            
            // Button to request notification permission
            Button(action: requestNotificationPermission) {
                Text("계속")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
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
                onNext()
            } else {
                print("Notification permission denied.")
            }
        }
        
    }
}

#Preview {
    return UsernameView(onNext: {
        print("Next button pressed")
    })
    .preferredColorScheme(.dark)
}
