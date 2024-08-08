import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        NSLog("LOG: AppDelegate init")
        FirebaseApp.configure()
        
        requestNotificationPermission(application: application)

        UNUserNotificationCenter.current().delegate = self

        return true
    }
}

// MARK: - Push Notification Delegate
extension AppDelegate {
    // Register for remote notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
        
        NotificationCenter.default.post(name: .didReceiveDeviceToken, object: nil, userInfo: ["deviceToken": tokenString])
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// MARK: - Notification and Microphone Permissions
extension AppDelegate {
    private func requestNotificationPermission(application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
}


extension Notification.Name {
    static let didReceiveDeviceToken = Notification.Name("didReceiveDeviceToken")
}
