//
//  SendingAmountView.swift
//  Vault
//
//  Created by Charles Lanier on 17/05/2024.
//

import SwiftUI

@MainActor
struct SendingAmountView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var model: Model

    @State private var showingConfirmation = false

    var body: some View {
        VStack {
            Spacer()

            FancyAmount(amount: self.$model.sendingAmount)

            Spacer()

            VStack(spacing: 32) {
                PrimaryButton("Send", disabled: self.model.parsedSendingAmount <= 0) {
                    self.showingConfirmation = true
                }

                NumPad(amount: self.$model.sendingAmount)
            }
        }
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultBackground()
        .navigationBarItems(
            leading: IconButton {
                self.dismiss()
            } icon: {
                Image(systemName: "chevron.left")
                    .iconify()
                    .fontWeight(.bold)
                    .padding(.trailing, 2)
            }
        )
        .removeNavigationBarBorder()
        .navigationBarBackButtonHidden(true)
        .sheetPopover(isPresented: self.$showingConfirmation) {
            ConfirmationView()
        }
    }
}

#if DEBUG
struct SendingAmountViewPreviews : PreviewProvider {

    @StateObject static var model = Model(vaultService: VaultService())

    static var previews: some View {
        SendingAmountView()
            .environmentObject(self.model)
    }
}
#endif
