//
//  StackedInvitationCard.swift
//  TentenInvitation
//
//  Created by 조윤근 on 10/8/24.
//

import Foundation
import SwiftUI

struct StackedInvitationCard: View {
    @Binding var showPopup: Bool
    var invitations: [Invitation]

    var body: some View {
        ZStack {
            if invitations.count > 1 {
                InvitationCard(showPopup: $showPopup, invitation: invitations[invitations.count - 2])
                    .offset(y: 20)
                    .scaleEffect(0.95)
            }
            InvitationCard(showPopup: $showPopup, invitation: invitations.last!)
        }
    }
}
