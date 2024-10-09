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
    
    @ObservedObject var viewModel = ContentViewModel.shared
    let repoManager = RepositoryManager.shared

    var body: some View {
        VStack {
            Text(invitation.username)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 5)
                .padding(.top, 5)

            
            if let uiImage = UIImage(data: invitation.profileImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.width * 0.3)
                    .clipShape(Circle())
                    .padding(.bottom, 10)
            } else {
                // Fallback image if data is not valid
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 0.3, height: UIScreen.main.bounds.width * 0.3)
                    .clipShape(Circle())
                    .padding(.bottom, 10)
            }
            
            Text("친구 요청이 왔어요🥳")
                .font(.body)
                .padding(.bottom, 20)
            
            VStack {
                Button(action: {
                    withAnimation {
                        accept()
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
                        decline()
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
    

    private func accept() {
        NSLog("LOG: accept")
        removeInvitationInFirebase()
        
        if !viewModel.receivedInvitations.isEmpty {
            viewModel.previousInvitationCount = viewModel.receivedInvitations.count
            removeInvitationInMemory()
        }
        if viewModel.receivedInvitations.isEmpty {
            withAnimation {
                viewModel.showPopup = false
            }
        }
    }
    
    private func decline() {
        NSLog("LOG: decline")
        // Remove invitation from firestore
        removeInvitationInFirebase()
        
        if !viewModel.receivedInvitations.isEmpty {
            viewModel.previousInvitationCount = viewModel.receivedInvitations.count
            removeInvitationInMemory()
        }
        if viewModel.receivedInvitations.isEmpty {
            withAnimation {
                viewModel.showPopup = false
            }
        }
    }
    
    private func removeInvitationInMemory() {
        if let index = viewModel.receivedInvitations.firstIndex(where: { $0.id == invitation.id }) {
            viewModel.receivedInvitations.remove(at: index)
        }
    }
    
    private func removeInvitationInFirebase() {
        guard let currentUserId = repoManager.userRecord?.id else {
            NSLog("LOG: userRecord is not set when removing invitation in firebase")
            return
        }
        let friendId = invitation.id
        
        repoManager.updateInvitationListInFirebase(documentId: currentUserId, friendId: friendId, action: .remove, listType: .received)
        repoManager.updateInvitationListInFirebase(documentId: friendId, friendId: currentUserId, action: .remove, listType: .sent)
    }
    private func removeInvitationInDatabase() {}
}
