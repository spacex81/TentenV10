
import SwiftUI

struct ProfileImageView: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    
    var onNext: () -> Void
    var onBack: () -> Void // Add closure to handle the back button action
    
    // Track the offset of the background image
    @State private var finalOffset: CGFloat = 0.0
    // Track the drag amount
    @State private var dragOffset: CGFloat = 0.0
    
    // Image offset value for local UI
    private var imageOffset: CGFloat {
        let offset = finalOffset + dragOffset
        print("ProfileImageView-imageOffset: \(offset)")
        return offset
    }
    
    var body: some View {
        ZStack {
            // Background image
            if let imageData = viewModel.profileImageData, let uiImage = UIImage(data: imageData) {
                GeometryReader { geometry in
                    let screenWidth = geometry.size.width
                    let screenHeight = UIScreen.main.bounds.height // Use full screen height
                    let imageAspectRatio = uiImage.size.width / uiImage.size.height
                    let scaledImageWidth = screenHeight * imageAspectRatio
                    
                    // Calculating the minimum and maximum allowable offsets
                    let minOffset = min(0, (screenWidth - scaledImageWidth) / 2) + 40
                    let maxOffset = max(0, (scaledImageWidth - screenWidth) / 2) - 40
                    
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: screenWidth, height: screenHeight) // Set frame to match the full screen size
                        .offset(x: imageOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width  // Update drag offset as the user drags
                                }
                                .onEnded { value in
                                    // Calculate the total offset after the drag ends
                                    finalOffset += value.translation.width
                                    
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.4)) {
                                        if finalOffset < minOffset {
                                            finalOffset = minOffset
                                        } else if finalOffset > maxOffset {
                                            finalOffset = maxOffset
                                        }
                                    }
                                    
                                    // Update viewModel's image offset when drag ends
                                    viewModel.imageOffset = Float(finalOffset)
                                    dragOffset = 0
                                }
                        )
                        .ignoresSafeArea()
                }
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            // Content on top of the image
            VStack {
                // Go Back Button
                HStack {
                    Button(action: {
                        onBack() // Handle the back action
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    Spacer()
                }
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                
                AddProfilePictureButton(onComplete: {
                    if viewModel.profileImageData != nil {
                        onNext() // Move to next onboarding page
                    }
                })
                
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.05)
                if viewModel.profileImageData != nil {
                    Button {
                        viewModel.profileImageData = nil
                        finalOffset = 0
                        viewModel.imageOffset = 0
                    } label: {
                        Text("Cancel")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(20)
                    }
                }
            }
        }
        .onAppear {
            NSLog("LOG: ProfileImageView rendered")
            // Synchronize finalOffset with the saved offset in the viewModel on appear
            finalOffset = CGFloat(viewModel.imageOffset)
        }
    }
}


#Preview {
    ProfileImageView(onNext: {
        print("Next button pressed")
    }, onBack: {
        print("Go back pressed")
    })
    .preferredColorScheme(.dark)
}
