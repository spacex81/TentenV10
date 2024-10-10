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
                    Text("이 앱을 사용 하기위해선")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("적어도 1명의 친구를")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("추가해야 해요")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    Text("여러분에게 소중한 친구를 추가해 보세요")
                    Text("언제나 대화 할 수 있어요🤗")
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
        .onAppear {
            NSLog("LOG: AddView")
        }
    }
}


#Preview {
    AddView {
        print("D")
    }
    .preferredColorScheme(.dark)
}
