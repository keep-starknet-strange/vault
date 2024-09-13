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

    var body: some View {
        VStack {
            Spacer()

            FancyAmount(amount: self.$model.amount)

            Spacer()

            VStack(spacing: 32) {
                PrimaryButton("Send", disabled: self.model.parsedAmount <= 0) {
                    self.model.showSendingConfirmation = true
                }

                NumPad(amount: self.$model.amount)
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
        .navigationTitle("Select Amount")
        .addSendingConfirmation(isPresented: self.$model.showSendingConfirmation) {
            self.model.showSendingView = false
        }
    }
}

#if DEBUG
struct SendingAmountViewPreviews : PreviewProvider {

    @StateObject static var model = {
        let model = Model()

        model.setRecipient(Recipient(name: "Very Long Bobby Name", phoneNumber: "+33612345678"))
        model.sendingStatus = .none

        return model
    }()

    static var previews: some View {
        SendingAmountView()
            .environmentObject(self.model)
    }
}
#endif
