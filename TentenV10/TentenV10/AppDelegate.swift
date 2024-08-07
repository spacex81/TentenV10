import Foundation
import UIKit
import FirebaseCore
import FirebaseAuth
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

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
        updateDeviceTokenIfNeeded(newToken: tokenString)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// MARK: - Device Token Management
extension AppDelegate {
    private func updateDeviceTokenIfNeeded(newToken: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let firebaseManager = FirebaseManager.shared
        let databaseManager = DatabaseManager.shared
        
        let homeViewModel = HomeViewModel()
        
        firebaseManager.fetchUserById(currentUserId) { result in
            switch result {
            case .success(let user):
                if user.deviceToken != newToken {
                    var updatedUser = user
                    updatedUser.deviceToken = newToken
                    // TODO: update local database user record with new device token
                    firebaseManager.updateUser(user: updatedUser) { updateResult in
                        switch updateResult {
                        case .success:
                            print("Device token updated successfully in Firestore.")
                        case .failure(let error):
                            print("Failed to update device token in Firestore: \(error.localizedDescription)")
                        }
                    }
                    
                    // Fetch the current user record from the local database
                    if var localUserRecord = databaseManager.fetchUser(id: currentUserId) {
                        // Update the device token in the local user record
                        localUserRecord.deviceToken = newToken
                        
                        // Save the updated user record back to the local database, and re-render ui
                        homeViewModel.updateDeviceTokenInLocalDatabase(userRecord: localUserRecord)
                        print("Device token updated successfully in the local database.")
                    } else {
                        print("Failed to fetch user record from the local database.")
                    }
                    ///
                } else {
                    print("Device token is already up to date.")
                }
            case .failure(let error):
                print("Failed to fetch user: \(error.localizedDescription)")
                FirebaseManager.shared.signOut { result in
                    switch result {
                    case .success:
                        NSLog("LOG: Sign out succeed")
                    case .failure(let error):
                        NSLog("LOG: Error signing out: \(error.localizedDescription)")
                    }
                }
            }
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
}

extension Notification.Name {
    static let didReceiveDeviceToken = Notification.Name("didReceiveDeviceToken")
}
