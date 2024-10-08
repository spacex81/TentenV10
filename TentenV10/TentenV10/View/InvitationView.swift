//
//  InvitationView.swift
//  TentenInvitation
//
//  Created by 조윤근 on 10/8/24.
//

import SwiftUI

struct InvitationView: View {
    @ObservedObject var viewModel = ContentViewModel.shared
    
    var body: some View {
        Color("DarkGray1")
            .opacity(1.0)
            .edgesIgnoringSafeArea(.all)
            .transition(.opacity)
            .animation(.easeInOut, value: viewModel.showPopup)
        
        let transitionType: AnyTransition = (viewModel.previousInvitationCount == 2 && viewModel.invitations.count == 1) ? .identity : .scale
        
        if viewModel.invitations.count == 1 {
            InvitationCard(showPopup: $viewModel.showPopup, invitation: viewModel.invitations.last!, onButtonPressed: viewModel.handleButtonPress)
                .transition(transitionType)
                .zIndex(1)
        } else if viewModel.invitations.count > 1 {
            StackedInvitationCard(showPopup: $viewModel.showPopup, invitations: viewModel.invitations, onButtonPressed: viewModel.handleButtonPress)
                .transition(.scale)
                .zIndex(1)
        }
    }
}

#Preview {
    InvitationView()
}
