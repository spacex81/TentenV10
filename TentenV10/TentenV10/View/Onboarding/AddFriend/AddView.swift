
import SwiftUI

struct AddView: View {
    @ObservedObject var viewModel = HomeViewModel.shared
    @ObservedObject var contentViewModel = ContentViewModel.shared
    
    @State private var showAddFriendView = false
    @State private var showSettingView = false

    var onNext: () -> Void
    var onBack: () -> Void // Add closure to handle the back button action
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    // Go Back Button
                    Button(action: {
                        onBack() // Handle the back action
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(20)
                    }
                    Spacer()
                }
                Spacer().frame(height: 30)
                HStack {
                    Spacer().frame(width: 30)
                    
                    PinButton(pin: viewModel.userRecord?.pin ?? "1234567")
                    Spacer()
                    
                    Button {
                        showSettingView.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer().frame(width: 30)
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                    .frame(height: 30)
                VStack {
                    if !contentViewModel.sentInvitations.isEmpty {
                        // Display names for each user in the invitation
                        Text("\(contentViewModel.sentInvitations.map { "\($0.username)님" }.joined(separator: " & "))에게 초대장을 보냈어요")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center) // Center align text if names are long
                        
                        Text("조금만 기다려주세요")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                    } else {
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
    AddView(onNext: {
        print("Next button pressed")
    }, onBack: {
        print("Go back pressed")
    })
    .preferredColorScheme(.dark)
}
