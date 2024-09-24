import SwiftUI

struct SettingView: View {
    @State private var isSheetPresented: Bool = false
    @ObservedObject var viewModel = HomeViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)


    var body: some View {
        VStack {
            Button(action: {
                authViewModel.signOut()
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
