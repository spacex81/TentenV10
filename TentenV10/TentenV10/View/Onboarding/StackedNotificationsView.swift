import SwiftUI

struct NotificationItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
}

struct StackedNotificationsView: View {
    @State private var notifications: [NotificationItem] = []
    
    var body: some View {
        ZStack {
            // Main content of the app
            VStack {
//                Button("Show Notification") {
                Button("알림 보이기") {
                    addNotification(message: "New Notification at \(Date())")
                }
                .padding()
                
                Spacer()
            }
            
            // Notification Stack
            VStack(spacing: 10) {
                ForEach(notifications) { notification in
                    NotificationBannerView(notification: notification, onDismiss: {
                        removeNotification(notification)
                    })
                    .transition(.move(edge: .top))
                }
            }
            .padding(.top, 50) // Adjust padding to move the stack down from the top
            .animation(.spring(), value: notifications) // Animate stack changes
        }
    }
    
    // Add a new notification to the stack
    private func addNotification(message: String) {
        let newNotification = NotificationItem(message: message)
        notifications.append(newNotification)
        
        // Automatically remove the notification after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            removeNotification(newNotification)
        }
    }
    
    // Remove a specific notification from the stack
    private func removeNotification(_ notification: NotificationItem) {
        notifications.removeAll { $0.id == notification.id }
    }
}

// Custom notification banner view
struct NotificationBannerView: View {
    let notification: NotificationItem
    var onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text(notification.message)
                .foregroundColor(.white)
                .padding()
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .padding(.trailing, 10)
            }
        }
        .background(Color.blue)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

// Preview of the stacked notifications
struct StackedNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        StackedNotificationsView()
            .preferredColorScheme(.dark)
    }
}
