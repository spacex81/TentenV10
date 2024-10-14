import Foundation
import AVFoundation
import UIKit
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        FirebaseApp.configure()
        

        
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("LOG: App is about to terminate")
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
    
    // Handle notifications when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification alert, sound, and badge in the foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            // For older iOS versions, continue using .alert (which is still available)
            completionHandler([.alert, .sound, .badge])
        }
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
    
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted")
                } else {
                    print("Microphone permission denied")
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("Microphone permission granted")
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }
}


extension Notification.Name {
    static let didReceiveDeviceToken = Notification.Name("didReceiveDeviceToken")
}
