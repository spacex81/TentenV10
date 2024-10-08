// UserDto with Firestore
import Foundation
import FirebaseFirestore

struct UserDto: Codable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var password: String
    var pin: String
    var hasIncomingCallRequest: Bool = false
    var profileImagePath: String?
    var deviceToken: String?
    var friends: [String] = []
    var roomName: String = "testRoom"
    var isBusy: Bool = false
    var socialLoginId: String
    var socialLoginType: String
    var imageOffset: Float = 0.0
    var receivedInvitations: [String] = []  // New field
    var sentInvitations: [String] = []      // New field

    init(id: String? = nil, email: String, username: String, password: String, pin: String, hasIncomingCallRequest: Bool = false, profileImagePath: String? = nil, deviceToken: String? = nil, friends: [String] = [], roomName: String = "testRoom", isBusy: Bool = false, socialLoginId: String, socialLoginType: String, imageOffset: Float = 0.0, receivedInvitations: [String] = [], sentInvitations: [String] = []) {
        self.id = id
        self.email = email
        self.username = username
        self.password = password
        self.pin = pin
        self.hasIncomingCallRequest = hasIncomingCallRequest
        self.profileImagePath = profileImagePath
        self.deviceToken = deviceToken
        self.friends = friends
        self.roomName = roomName
        self.isBusy = isBusy
        self.socialLoginId = socialLoginId
        self.socialLoginType = socialLoginType
        self.imageOffset = imageOffset
        self.receivedInvitations = receivedInvitations
        self.sentInvitations = sentInvitations
    }
}
