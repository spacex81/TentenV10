import SwiftUI

struct AddProfilePictureButton: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    private let repoManager = RepositoryManager.shared
    
    @State private var hue: Double = 0.0
    @State private var colors: [Color] = [
        Color(hue: 0.0, saturation: 1, brightness: 1),
        Color(hue: 0.1, saturation: 1, brightness: 1)
    ]
    
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage?
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            
            if let profileImageData = viewModel.profileImageData {
                guard var newUserRecord = viewModel.userRecord else {
                    NSLog("LOG: UserRecord is not set when setting profile image during onboarding")
                    return
                }

                DispatchQueue.main.async {
                    if let onComplete = onComplete {
                        onComplete()
                    }
                }

                NSLog("LOG: Profile image storing process begin")

                // Perform background tasks without blocking the main thread
                DispatchQueue.global(qos: .background).async {
                    newUserRecord.profileImageData = profileImageData
                    newUserRecord.imageOffset = viewModel.imageOffset
                    
                    // Store profile image data on memory (main thread update)
                    DispatchQueue.main.async {
                        viewModel.userRecord = newUserRecord
                    }
                    
                    // Store profile image data on local database
                    repoManager.createUserInDatabase(user: newUserRecord)
                    
                    // Asynchronous Firebase operations
                    Task {
                        do {
                            // Store profile image on Firebase storage and get the image URL
                            let profileImagePath = try await repoManager.saveProfileImageInFirebase(id: newUserRecord.id, profileImageData: newUserRecord.profileImageData!)
                            
                            // Store profile image path and imageOffset to Firebase Firestore
                            let fieldsToUpdate: [String: Any] = [
                                "profileImagePath": profileImagePath,
                                "imageOffset": newUserRecord.imageOffset
                            ]
                            repoManager.updateUserField(userId: newUserRecord.id, fieldsToUpdate: fieldsToUpdate)
                            
                            NSLog("LOG: Profile image path successfully updated in Firestore")
                        } catch {
                            NSLog("LOG: Error storing new profile image: \(error.localizedDescription)")
                        }
                    }
                }

                NSLog("LOG: Moving on to next page")

            } else {
                isImagePickerPresented = true
            }
        }) {
            ZStack {
                LinearGradient(gradient: Gradient(colors: colors), startPoint: .trailing, endPoint: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                if viewModel.profileImageData == nil {
                    Text("choose a picture")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(20)
                } else {
                    Text("set as profile picture")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(20)
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear {
            startHueRotation()
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                var finalImage = image
                // Resize image
                if image.size.width > maxImageSize.width || image.size.height > maxImageSize.height {
                    if let resizedImage = resizeImage(image, targetSize: maxImageSize) {
                        finalImage = resizedImage
                    } else {
                        NSLog("LOG: Error resizing image")
                        return
                    }
                }
                //
                
                let imageData = finalImage.jpegData(compressionQuality: 0.8)
                viewModel.profileImageData = imageData
            }
        }
    }
    
    private func startHueRotation() {
        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation {
                hue += 0.01
                if hue > 1.0 { hue = 0.0 }
                updateColors()
            }
        }
    }

    private func updateColors() {
        colors = [
            Color(hue: hue, saturation: 1, brightness: 1),
            Color(hue: (hue + 0.1).truncatingRemainder(dividingBy: 1.0), saturation: 1, brightness: 1)
        ]
    }
}

#Preview {
    AddProfilePictureButton()
        .preferredColorScheme(.dark)
}


