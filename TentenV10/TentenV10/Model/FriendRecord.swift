import GRDB
import SwiftUI

struct FriendRecord: Codable, FetchableRecord, PersistableRecord, Equatable, Identifiable {
    var id: String
    var email: String
    var username: String
    var pin: String
    var profileImageData: Data?
    var deviceToken: String?
    var userId: String // Foreign key to UserRecord
    var isBusy: Bool = false
    var lastInteraction: Date?
    var isAccepted: Bool = true
    var status: String = "foreground" // New status field with default value

    // Define the primary key for the table
    static var databaseTableName: String = "friends"

    enum Columns: String, ColumnExpression {
        case id, email, username, pin, profileImageData, deviceToken, userId, isBusy, lastInteraction, isAccepted, status
    }

    // Define how to encode to and decode from the database
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.email] = email
        container[Columns.username] = username
        container[Columns.pin] = pin
        container[Columns.profileImageData] = profileImageData
        container[Columns.deviceToken] = deviceToken
        container[Columns.userId] = userId
        container[Columns.isBusy] = isBusy
        container[Columns.lastInteraction] = lastInteraction
        container[Columns.isAccepted] = isAccepted
        container[Columns.status] = status // Encode the new status field
    }
}

extension FriendRecord {
    static var empty: FriendRecord {
        return FriendRecord(
            id: "",
            email: "",
            username: "",
            pin: "",
            profileImageData: nil,
            deviceToken: nil,
            userId: "",
            isBusy: false,
            lastInteraction: nil,
            isAccepted: true,
            status: "foreground" // Default value for the new property
        )
    }
}
