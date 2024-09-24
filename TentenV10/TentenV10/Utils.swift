//
//  Utils.swift
//  TentenV10
//
//  Created by 조윤근 on 9/4/24.
//

import Foundation
import UIKit
import CryptoKit

enum OnboardingStep {
    case username
    case profileImage
    case addFriend
    case home
}

let maxImageSize = CGSize(width: 1024, height: 1024)

func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Determine the scaling factor that preserves aspect ratio
    let scaleFactor = min(widthRatio, heightRatio)

    // Compute the new size that preserves aspect ratio
    let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

    // Resize the image
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
}

func generateUUID() -> String {
    let uuid = UUID().uuidString
    print("Generated UUID: \(uuid)")
    return uuid
}

func generateHash(from input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined() // Convert hash bytes to a hex string
    print("Generated Hash: \(hashString)")
    return hashString
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return emailPredicate.evaluate(with: email)
}
