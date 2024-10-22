import SwiftUI

struct SettingView: View {
    @State private var isSheetPresented: Bool = false
    @State private var showDeleteConfirmation: Bool = false // State for confirmation alert
    @ObservedObject var viewModel = HomeViewModel.shared
    @ObservedObject var authViewModel = AuthViewModel.shared
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack {
            // Log Out Button with red background and white text
            Button(action: {
                authViewModel.signOut()
            }) {
                Text("로그아웃")
                    .font(.title2)
                    .foregroundColor(.white) // White text
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red) // Red background
                    .cornerRadius(30) // Rounded corners
                    .padding(.horizontal)
            }
            
            // Account Deletion Button with white background and red text
            Button(action: {
                // Show confirmation alert before deleting account
                showDeleteConfirmation = true
            }) {
                Text("계정 삭제")
                    .font(.title2)
                    .foregroundColor(.red) // Red text
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground)) // System background
                    .cornerRadius(10) // Rounded corners
                    .padding(.horizontal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10) // Border for additional contrast
                            .stroke(Color.red, lineWidth: 0)
                    )
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("계정 삭제"),
                    message: Text("정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                    primaryButton: .destructive(Text("삭제")) {
                        // Handle account deletion
                        deleteAccount()
                    },
                    secondaryButton: .cancel(Text("취소"))
                )
            }

        }
        .padding(30)
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .frame(maxWidth: .infinity)
    }

    // Function to handle account deletion
    private func deleteAccount() {
        authViewModel.deleteAccount()
    }
}

#Preview {
    SettingView()
        .preferredColorScheme(.dark)
}
