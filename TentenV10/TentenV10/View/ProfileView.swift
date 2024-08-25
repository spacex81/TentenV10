import SwiftUI

struct ProfileView: View {
    @State private var isSheetPresented: Bool = false

    var body: some View {
        VStack {
            Button {
                isSheetPresented = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .tint(.white)
                        .fontWeight(.bold)
                        .font(.title2)
                    Text("add friends")
                        .tint(.white)
                        .fontWeight(.bold)
                        .font(.title2)
                    Spacer()
                }
                .padding(25)
                .background(Color(UIColor(white: 0.3, alpha: 1.0)))
                .cornerRadius(20)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
        }
        .sheet(isPresented: $isSheetPresented) {
            AddFriendView()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
