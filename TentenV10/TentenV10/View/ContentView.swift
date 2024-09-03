//import SwiftUI
//import FirebaseAuth
//
//struct ContentView: View {
//    @ObservedObject var viewModel = ContentViewModel()
//    
//    var body: some View {
//        VStack {
//            if viewModel.isUserLoggedIn {
//                HomeView()
//            } else {
//                AuthView()
//            }
//        }
//        .environmentObject(viewModel)
//    }
//}
//
import SwiftUI
import FirebaseAuth

struct ContentView: View {
    
    let iconSize = 20.0
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("apple")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .border(.red)
                Text("Sign in with Apple")
                    .font(.headline)
                    .padding(.leading, 8)
                    .border(.green)
            }
            .padding(.vertical, 10)
            .border(.black)
            
            HStack {
                Image("google")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .border(.red)
                Text("Sign in with Google")
                    .font(.headline)
                    .padding(.leading, 8)
                    .border(.green)
            }
            .padding(.vertical, 10)
            .border(.black)
            
            HStack {
                Image("kakao")
                    .resizable()
                    .frame(width: iconSize, height: iconSize)
                    .border(.red)
                Text("Sign in with Kakao")
                    .font(.headline)
                    .padding(.leading, 8)
                    .border(.green)
            }
            .padding(.vertical, 10)
            .border(.black)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
