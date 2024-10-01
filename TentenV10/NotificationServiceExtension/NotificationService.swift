import UserNotifications
import Intents
import UIKit
import GRDB
import os.log

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    var dbPool: DatabasePool?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        os_log("Notification received in service extension")
        os_log("Notification content: %{public}@", "\(request.content.userInfo)")
        
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.GHJU9V8GHS.tech.komaki.TentenV10") {
            let databaseURL = appGroupURL.appendingPathComponent("db.sqlite")
            do {
                dbPool = try DatabasePool(path: databaseURL.path)
                
                // Perform database operations here
                fetchFriends()
                
            } catch {
                NSLog("Failed to open database in extension: \(error.localizedDescription)")
            }
        }
        
        if let customData = request.content.userInfo["customData"] as? [String: Any],
           let senderId = customData["senderId"] as? String {
            os_log("Sender's ID: %{public}@", senderId)
            
            // Fetch the FriendRecord corresponding to senderId
            fetchFriendRecord(senderId: senderId) { friendRecord in
                guard let friendRecord = friendRecord else {
                    os_log("Friend record not found for senderId: %{public}@", senderId)
                    return
                }
                
                // Update the notification with the friend’s username and profile image
                if let profileImageData = friendRecord.profileImageData,
                   let profileImage = UIImage(data: profileImageData) {
                    self.setAppIconToCustom(username: friendRecord.username, avatarImage: profileImage, request: request, contentHandler: contentHandler)
                } else {
                    self.setAppIconToCustom(username: friendRecord.username, request: request, contentHandler: contentHandler)
                }
            }
        }

        // Modify the notification content with custom logic
//        setAppIconToCustom(request: request, contentHandler: contentHandler)
    }
    
    func fetchFriendRecord(senderId: String, completion: @escaping (FriendRecord?) -> Void) {
        do {
            let friendRecord = try dbPool?.read { db in
                try FriendRecord.fetchOne(db, key: senderId)
            }
            completion(friendRecord)
        } catch {
            os_log("Error fetching friend for senderId: %{public}@", senderId)
            completion(nil)
        }
    }

    
    func fetchFriends() {
        do {
            let friends = try dbPool?.read { db in
                try FriendRecord.fetchAll(db)
            }
            print(friends ?? "No friends found")
        } catch {
            NSLog("Error fetching friends: \(error)")
        }
    }
    
    private func setAppIconToCustom(username: String, avatarImage: UIImage? = nil, request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        var avatar: INImage? = nil
        if let avatarImage = avatarImage {
            avatar = INImage(imageData: avatarImage.pngData()!)
        } else {
            // Fallback to default image
            avatar = INImage(imageData: UIImage(named: "user1")!.pngData()!)
        }
        
        // Configure the sender and receiver with the friend’s username and profile image
        let senderPerson = INPerson(
            personHandle: INPersonHandle(value: "unique-sender-id", type: .unknown),
            nameComponents: nil,
            displayName: username,
            image: avatar,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: false,
            suggestionType: .none
        )

        let mePerson = INPerson(
            personHandle: INPersonHandle(value: "unique-me-id", type: .unknown),
            nameComponents: nil,
            displayName: nil,
            image: nil,
            contactIdentifier: nil,
            customIdentifier: nil,
            isMe: true,
            suggestionType: .none
        )
        
        // Create the INSendMessageIntent
        let intent = INSendMessageIntent(
            recipients: [mePerson],
            outgoingMessageType: .outgoingMessageText,
            content: request.content.body,
            speakableGroupName: nil,
            conversationIdentifier: "unique-conversation-id",
            serviceName: nil,
            sender: senderPerson,
            attachments: nil
        )
        
        intent.setImage(avatar, forParameterNamed: \.sender)
        
        // Create the interaction and donate it
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        
        interaction.donate { error in
            if let error = error {
                print("Error donating interaction: \(error)")
                // If error occurs, pass the default content without the image
                contentHandler(self.bestAttemptContent!)
                return
            }

            do {
                // Update the notification with the intent
                let updatedContent = try request.content.updating(from: intent)
                contentHandler(updatedContent)
            } catch {
                print("Error updating notification content: \(error)")
                // In case of an error, display the default notification
                contentHandler(self.bestAttemptContent!)
            }
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this to deliver your "best attempt" at modified content, or the original content will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
