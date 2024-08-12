import SwiftUI

struct AuthView: View {
    @State var isLoginMode: Bool = true
    @ObservedObject var viewModel = AuthViewModel()
    @State private var isImagePickerPresented = false

    var body: some View {
        VStack {
            Picker(selection: $isLoginMode, label: Text("Mode")) {
                Text("Login")
                    .tag(true)
                Text("Sign Up")
                    .tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if !isLoginMode {
                Button(action: {
                    isImagePickerPresented.toggle()
                }) {
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            
            TextField("Email", text: $viewModel.email)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)

            SecureField("Password", text: $viewModel.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(5.0)
            
            Button(action: {
                isLoginMode ? viewModel.signIn() : viewModel.signUp()
            }) {
                Text(isLoginMode ? "Login" : "Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10.0)
            }
            .padding(.top, 20)
        }
        .fullScreenCover(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $viewModel.selectedImage)
        }
    }
}
