import Foundation
import FirebaseFirestore

struct RoomDto: Codable {
    @DocumentID var id: String?
    var userId1: String
    var userId2: String
    var lastInteraction: Timestamp
    var nickname: String
    var isActive: Int = 0  // Changed to Int with a default value of 0
    
    init(id: String? = nil, userId1: String, userId2: String, lastInteraction: Date, nickname: String, isActive: Int = 0) {
        self.id = id
        self.userId1 = userId1
        self.userId2 = userId2
        self.lastInteraction = Timestamp(date: lastInteraction)
        self.nickname = nickname
        self.isActive = isActive
    }
}

extension RoomDto {
    // Helper method to create the room document ID from user IDs
    static func generateRoomId(userId1: String, userId2: String) -> String {
        // Sort the user IDs lexicographically and combine with '_'
        let sortedIds = [userId1, userId2].sorted()
        return "\(sortedIds[0])_\(sortedIds[1])"
    }
    
    static func generateRoomNickName(username1: String, username2: String) -> String {
        let sortedNames = [username1, username2].sorted()
        return "\(sortedNames[0])_\(sortedNames[1])"
    }
    
    func getFriendId(currentUserId: String) -> String? {
        // Return the other userId that is not the currentUserId
        if currentUserId == userId1 {
            return userId2
        } else if currentUserId == userId2 {
            return userId1
        } else {
            // Return nil if the currentUserId doesn't match either userId1 or userId2
            return nil
        }
    }
}
