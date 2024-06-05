//
//  SendingView.swift
//  Vault
//
//  Created by Charles Lanier on 21/05/2024.
//

import SwiftUI

struct SendingView: View {

    @EnvironmentObject var model: Model

    var body: some View {
        NavigationStack {
            SendingRecipientView()
        }
    }
}

#Preview {
    SendingView()
}
