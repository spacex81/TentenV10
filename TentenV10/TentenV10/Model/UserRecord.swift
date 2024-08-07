//import Foundation
//import GRDB
//
//struct UserRecord: Codable, FetchableRecord, PersistableRecord {
//    var id: String
//    var email: String
//    var username: String
//    var pin: String
//    var hasIncomingCallRequest: Bool = false
//    var profileImageData: Data?
//    var deviceToken: String?
//    // TODO: need to add a list of friend ids
//
//    // Define the primary key for the table
//    static var databaseTableName: String = "users"
//
//    enum Columns: String, ColumnExpression {
//        case id, email, username, pin, hasIncomingCallRequest, profileImageData, deviceToken
//    }
//
//    // Define how to encode to and decode from the database
//    func encode(to container: inout PersistenceContainer) {
//        container[Columns.id] = id
//        container[Columns.email] = email
//        container[Columns.username] = username
//        container[Columns.pin] = pin
//        container[Columns.hasIncomingCallRequest] = hasIncomingCallRequest
//        container[Columns.profileImageData] = profileImageData
//        container[Columns.deviceToken] = deviceToken
//    }
//}

import Foundation
import GRDB

//struct UserRecord: Codable, FetchableRecord, PersistableRecord {
struct UserRecord: Codable, FetchableRecord, PersistableRecord, Equatable {
    var id: String
    var email: String
    var username: String
    var pin: String
    var hasIncomingCallRequest: Bool = false
    var profileImageData: Data?
    var deviceToken: String?
    var friends: [String] = [] // New property for friend IDs

    // Define the primary key for the table
    static var databaseTableName: String = "users"

    enum Columns: String, ColumnExpression {
        case id, email, username, pin, hasIncomingCallRequest, profileImageData, deviceToken, friends
    }

    // Define how to encode to and decode from the database
    func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.email] = email
        container[Columns.username] = username
        container[Columns.pin] = pin
        container[Columns.hasIncomingCallRequest] = hasIncomingCallRequest
        container[Columns.profileImageData] = profileImageData
        container[Columns.deviceToken] = deviceToken
        // Encode friends array as a JSON string
        if let friendsData = try? JSONEncoder().encode(friends) {
            container[Columns.friends] = String(data: friendsData, encoding: .utf8)
        }
    }
}
