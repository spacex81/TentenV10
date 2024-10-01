import SwiftUI

struct AddFriendButtonPreview: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    
    var body: some View {
        VStack {
            Spacer()
            Button {
                if viewModel.friendPin.count == 0 {
                    viewModel.friendPin = "1234567"
                } else {
                    viewModel.friendPin = ""
                }
            } label: {
                Text("Click")
            }
            Spacer()
//            if viewModel.friendPin.count > 0 {
//                Text(viewModel.friendPin)
//                    .font(.largeTitle)
//            }
            Spacer()
            AddFriendButton()
            Spacer()
        }
    }
}

#Preview {
    AddFriendButtonPreview()
        .preferredColorScheme(.dark)
}
