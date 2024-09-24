import SwiftUI

struct EmailView: View {
    @ObservedObject var viewModel = AuthViewModel.shared
    @Binding var showEmailView: Bool // Binding to control visibility of EmailView
    
    var body: some View {
        VStack {
            TextField("Email", text: $viewModel.email)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)

            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
            
            if !viewModel.errorMsg.isEmpty {
                Text(viewModel.errorMsg)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 5)
            }
            
            Button(action: {
                viewModel.emailSignIn()
                showEmailView = false
            }) {
                Text("Sign In")
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10.0)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    viewModel.stopLoading(for: .email)
                    showEmailView = false
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .fontWeight(.heavy)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmailView(showEmailView: .constant(true)) // For preview purposes
            .preferredColorScheme(.dark)
    }
}
