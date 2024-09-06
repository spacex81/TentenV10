import SwiftUI

struct AddView: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    @State private var showAddFriendView = false
    @State private var showSettingView = false

    var onNext: () -> Void
    
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 30)
                HStack {
                    Spacer().frame(width: 30)
                    
                    Button {
                        showSettingView.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    PinButton(pin: viewModel.userRecord?.pin ?? "1234567")
                    Spacer().frame(width: 30)
                }
                Spacer()
            }
            VStack {
                VStack {
                    Text("add more friends")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("you need at least 1 friend to")
                    Text("accept your request")
                }
                .padding(.bottom, 50)
                
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    showAddFriendView.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .padding(20)
                        .background(Color(white: 0.3))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )
                }
            }
        }
        .sheet(isPresented: $showAddFriendView) {
            AddFriendView()
        }
        .sheet(isPresented: $showSettingView) {
            SettingView()
        }
        .onChange(of: viewModel.userRecord?.friends.count ?? 0) { _ , newCount in
            if newCount > 0 {
                onNext()
            }
        }
    }
}


#Preview {
    AddView {
        print("D")
    }
    .preferredColorScheme(.dark)
}
