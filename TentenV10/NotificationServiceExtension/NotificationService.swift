import UserNotifications
import Intents
import UIKit
import os.log

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        os_log("Notification received in service extension")
        os_log("Notification content: %{public}@", "\(request.content.userInfo)")
        
        //
        if let sharedDefaults = UserDefaults(suiteName: "group.GHJU9V8GHS.tech.komaki.TentenV10"),
           let sharedData = sharedDefaults.string(forKey: "sharedKey") {
            os_log("Shared data: %{public}@", sharedData) // This should log "Hello from Main App"
        }
        //
        
        // Modify the notification content with custom logic
        setAppIconToCustom(request: request, contentHandler: contentHandler)
    }
    
    private func setAppIconToCustom(request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        // Load the custom image ("user1") from your asset catalog
        guard let avatarImage = UIImage(named: "user1") else {
            // Fallback: If image is missing, show the default notification
            contentHandler(bestAttemptContent!)
            return
        }

        // Convert UIImage to INImage for the intent
        let avatar = INImage(imageData: avatarImage.pngData()!)

        // Configure the sender and receiver with their images and properties
        let senderPerson = INPerson(
            personHandle: INPersonHandle(value: "unique-sender-id", type: .unknown),
            nameComponents: nil,
            displayName: "Sender name",
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

        // Attach the custom image to the sender
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
