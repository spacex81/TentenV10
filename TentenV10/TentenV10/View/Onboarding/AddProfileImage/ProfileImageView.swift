
import SwiftUI

struct ProfileImageView: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    
    var onNext: () -> Void
    var onBack: () -> Void // Add closure to handle the back button action
    
    
    var body: some View {
        return ZStack {
//            ImagePickerViewRepresentable()
            ImagePickerViewRepresentable(onNext: onNext) 
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        onBack() // Handle the back action
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    Spacer() // Push button to the left
                }
                Spacer() // Push button to the top
            }
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
