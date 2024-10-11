import SwiftUI
import Combine

struct SplashView: View {
    @State private var isActive = false
    @ObservedObject var viewModel = HomeViewModel.shared
    let repoManager = RepositoryManager.shared

    var body: some View {
        ZStack {
            Image("app_bg")
                .resizable()
                .scaledToFill() // Scale the image to fill the screen
                .ignoresSafeArea()
            
            Image("app_logo")
        }
        .onAppear {
            NSLog("LOG: SplashView-onAppear")
            
            // Show splash screen for 1 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isActive = true
                }
            }
            
            
//            syncFriendInfo()
        }
        .fullScreenCover(isPresented: $isActive) {
            // Navigate to ContentView after the splash screen
            ContentView()
        }
    }
}

extension SplashView {
//    func syncFriendInfo() {
//        Task {
//            NSLog("LOG: SplashView-syncFriendInfo")
//            // Ensure we have the user record and the list of friends
//            guard var friendIds = repoManager.userRecord?.friends else {
//                NSLog("LOG: No friends to sync.")
//                return
//            }
//
//            // Create a list to keep track of friends to remove
//            var friendsToRemove: [String] = []
//
//            // Iterate over each friend ID
//            for friendId in friendIds {
//                do {
//                    // Check if the friend has deleted the current user
//                    let isDeleted = try await repoManager.checkIfFriendDeletedYou(friendId: friendId, currentUserId: repoManager.userRecord?.id ?? "")
//                    if isDeleted {
//                        // If the friend has deleted the user, add their ID to the list for removal
//                        friendsToRemove.append(friendId)
//                    }
//                } catch {
//                    NSLog("LOG: Error checking if friend deleted you for friendId \(friendId): \(error.localizedDescription)")
//                }
//            }
//
//            // Remove friends who have deleted the user from the user record
//            if !friendsToRemove.isEmpty {
//                // Update the userRecord with filtered friendIds
//                friendIds.removeAll { friendsToRemove.contains($0) }
//                repoManager.userRecord?.friends = friendIds
//                
//                // Update the database or Firestore if needed
//                // Example: repoManager.updateUserRecordInDatabase(repoManager.userRecord)
//                NSLog("LOG: Updated userRecord friends after sync: \(friendIds)")
//            }
//        }
//    }
}

// Preview for SplashView
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
