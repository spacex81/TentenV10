import Foundation
import FirebaseFirestore

struct UserDto: Codable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var pin: String
    var hasIncomingCallRequest: Bool = false
    var profileImagePath: String?
    var deviceToken: String?
    var friends: [String] = []
    var roomName: String = "testRoom"
    var isBusy: Bool = false  // New field with default value
    
    init(id: String? = nil, email: String, username: String, pin: String, hasIncomingCallRequest: Bool = false, profileImagePath: String? = nil, deviceToken: String? = nil, friends: [String] = [], roomName: String = "testRoom", isBusy: Bool = false) {
        self.id = id
        self.email = email
        self.username = username
        self.pin = pin
        self.hasIncomingCallRequest = hasIncomingCallRequest
        self.profileImagePath = profileImagePath
        self.deviceToken = deviceToken
        self.friends = friends
        self.roomName = roomName
        self.isBusy = isBusy
    }
}
