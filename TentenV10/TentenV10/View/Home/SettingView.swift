import SwiftUI

struct SettingView: View {
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)


    var body: some View {
        VStack {
//            if let userRecord = viewModel.userRecord, let imageData = userRecord.profileImageData, let uiImage = UIImage(data: imageData) {
//                
//                // user profile panel
//                HStack {
//                    // username and pin
//                    VStack(alignment: .leading) {
//                        Text(userRecord.username)
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .padding(.bottom, 1)
//                        if let userPin = viewModel.userRecord?.pin {
//                            PinButton(pin: userPin)
//                        }
//                    }
//                    Spacer()
//                    // profile pic
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 100, height: 100)
//                        .clipShape(Circle())
//                        .shadow(radius: 10)
//                }
//                .padding(10)
//                
//                // add friends button
//                Button {
//                    isSheetPresented = true
//                    impactFeedback.impactOccurred()
//                } label: {
//                    HStack {
//                        Image(systemName: "plus")
//                            .tint(.white)
//                            .fontWeight(.bold)
//                            .font(.title2)
//                        Text("add friends")
//                            .tint(.white)
//                            .fontWeight(.bold)
//                            .font(.title2)
//                        Spacer()
//                    }
//                    .padding(25)
//                    .background(Color(UIColor(white: 0.3, alpha: 1.0)))
//                    .cornerRadius(20)
//                    .frame(maxWidth: .infinity)
//                }
//                .frame(maxWidth: .infinity)
//                
//                Spacer()
//
//            }
            
            Button(action: {
                viewModel.signOut()
            }) {
                Text("Sign Out")
                    .font(.title2)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding(30)
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .frame(maxWidth: .infinity)
    }
}



#Preview {
    SettingView()
        .preferredColorScheme(.dark)
}
