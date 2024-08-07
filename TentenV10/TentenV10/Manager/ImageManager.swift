import UIKit

class ImageManager {
    static let shared = ImageManager()
    
    func saveImageToLocalDirectory(image: UIImage, filename: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsURL.appendingPathComponent("\(filename).jpg")
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImageFromLocalDirectory(filePath: String) -> UIImage? {
        return UIImage(contentsOfFile: filePath)
    }
    
    func deleteImageFromLocalDirectory(filePath: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: filePath)
        } catch {
            print("Error deleting image: \(error)")
        }
    }
}
