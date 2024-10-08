//
//  InvitationCard.swift
//  TentenInvitation
//
//  Created by 조윤근 on 10/8/24.
//

import Foundation
import SwiftUI

struct InvitationCard: View {
    @Binding var showPopup: Bool
    var invitation: Invitation
    var onButtonPressed: () -> Void

    var body: some View {
        VStack {
            Text(invitation.name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
            
            Image(invitation.name)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.width * 0.3)
                .clipShape(Circle())
                .padding(.bottom, 10)
            
            Text("친구 요청이 왔어요🥳")
                .font(.body)
                .padding(.bottom, 20)
            
            VStack {
                Button(action: {
                    withAnimation {
                        onButtonPressed()
                    }
                }) {
                    Text("수락")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(25)
                }
                .padding(.bottom, 10)
                
                Button(action: {
                    withAnimation {
                        onButtonPressed()
                    }
                }) {
                    Text("거절")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("DarkGray2"))
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.width * 0.9)
        .padding()
        .background(Color("DarkGray2"))
        .cornerRadius(50)
        .overlay(
            RoundedRectangle(cornerRadius: 50)
                .stroke(Color.gray, lineWidth: 1)
                .opacity(0.3)
        )
        .shadow(radius: 10)
    }
}
