import SwiftUI

struct UsernameView: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    @State private var isTextFieldFocused = true // Automatically focus when the view appears

    var onNext: () -> Void // The closure to call when the "Next" button is pressed
    

    var body: some View {
        VStack {
            HStack {
                FocusTextField(text: $viewModel.username, isFocused: $isTextFieldFocused)
                    .frame(height: 40)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            HStack {
                Spacer()

                AddUsernameButton(onComplete: {
                    isTextFieldFocused = false
                    onNext() // Move to next onboarding page
                })
                
                Spacer()
                    .frame(width: 20)
            }
            .padding(.top, 20)
        }
        .onAppear {
            NSLog("LOG: UsernameView rendered")
            isTextFieldFocused = true // Focus the text field on appearance
        }
    }
}

#Preview {
    @State var username: String = "TestUser"

    return UsernameView(onNext: {
        print("Next button pressed")
    })
    .preferredColorScheme(.dark)
}
