//
//  DeleteFriendView.swift
//  TentenV10
//
//  Created by 조윤근 on 10/1/24.
//

import SwiftUI

struct DeleteFriendView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()

            Button {
                
            } label: {
                Text("delete friend")
            }
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("close")
            }
            Spacer()

        }
    }
}

#Preview {
    DeleteFriendView()
        .preferredColorScheme(.dark)
}
