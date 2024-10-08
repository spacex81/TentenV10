import GRDB
import SwiftUI

struct UserRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: String
    var email: String
    var username: String
    var password: String
    var pin: String
    var hasIncomingCallRequest: Bool = false
    var profileImageData: Data?
    var deviceToken: String?
    var friends: [String] = []
    var roomName: String = "testRoom"
    var isBusy: Bool = false
    var socialLoginId: String
    var socialLoginType: String
    var imageOffset: Float = 0.0
    var receivedInvitations: [String] = []  // Add this field
    var sentInvitations: [String] = []      // Add this field

    static var databaseTableName: String = "users"

    enum Columns: String, ColumnExpression {
        case id, email, username, password, pin, hasIncomingCallRequest, profileImageData, deviceToken, friends, roomName, isBusy, socialLoginId, socialLoginType, imageOffset, receivedInvitations, sentInvitations
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.email] = email
        container[Columns.username] = username
        container[Columns.password] = password
        container[Columns.pin] = pin
        container[Columns.hasIncomingCallRequest] = hasIncomingCallRequest
        container[Columns.profileImageData] = profileImageData
        container[Columns.deviceToken] = deviceToken
        if let friendsData = try? JSONEncoder().encode(friends) {
            container[Columns.friends] = String(data: friendsData, encoding: .utf8)
        }
        container[Columns.roomName] = roomName
        container[Columns.isBusy] = isBusy
        container[Columns.socialLoginId] = socialLoginId
        container[Columns.socialLoginType] = socialLoginType
        container[Columns.imageOffset] = imageOffset
        if let receivedData = try? JSONEncoder().encode(receivedInvitations) {
            container[Columns.receivedInvitations] = String(data: receivedData, encoding: .utf8)
        }
        if let sentData = try? JSONEncoder().encode(sentInvitations) {
            container[Columns.sentInvitations] = String(data: sentData, encoding: .utf8)
        }
    }
}
