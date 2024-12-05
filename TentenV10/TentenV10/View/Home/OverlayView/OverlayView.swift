import SwiftUI

struct OverlayView: View {
    @State private var showExploreGrid: Bool = true // State to toggle between views

    var body: some View {
        ZStack {
            if showExploreGrid {
                // First view: Explore Grid View
                ExploreGridView()
            } else {
                // Second view: Timer View
                TimerView()
            }
        }
    }
}

#Preview {
    OverlayView()
}
