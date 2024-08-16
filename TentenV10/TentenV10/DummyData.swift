import Foundation
import UIKit

struct DummyData {
    static let dummyUsers: [FriendRecord] = [
        FriendRecord(
            id: UUID().uuidString,
            email: "user1@example.com",
            username: "User One",
            pin: "1234",
            profileImageData: UIImage(named: "user1")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token1",
            userId: "user1"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user2@example.com",
            username: "User Two",
            pin: "5678",
            profileImageData: UIImage(named: "user2")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token2",
            userId: "user2"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user3@example.com",
            username: "User Three",
            pin: "9012",
            profileImageData: UIImage(named: "user3")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token3",
            userId: "user3"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user4@example.com",
            username: "User Four",
            pin: "3456",
            profileImageData: UIImage(named: "user4")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token4",
            userId: "user4"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user5@example.com",
            username: "User Five",
            pin: "7890",
            profileImageData: UIImage(named: "user5")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token5",
            userId: "user5"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user6@example.com",
            username: "User Six",
            pin: "1122",
            profileImageData: UIImage(named: "user6")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token6",
            userId: "user6"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user7@example.com",
            username: "User Seven",
            pin: "3344",
            profileImageData: UIImage(named: "user7")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token7",
            userId: "user7"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user8@example.com",
            username: "User Eight",
            pin: "5566",
            profileImageData: UIImage(named: "user8")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token8",
            userId: "user8"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user9@example.com",
            username: "User Nine",
            pin: "7788",
            profileImageData: UIImage(named: "user9")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token9",
            userId: "user9"
        ),
        FriendRecord(
            id: UUID().uuidString,
            email: "user10@example.com",
            username: "User Ten",
            pin: "9900",
            profileImageData: UIImage(named: "user10")?.jpegData(compressionQuality: 1.0),
            deviceToken: "token10",
            userId: "user10"
        )
    ]
}
