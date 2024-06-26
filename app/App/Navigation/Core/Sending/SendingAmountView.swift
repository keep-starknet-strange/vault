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
        .sheet(isPresented: self.$model.showSendingConfirmation) {
            if self.model.sendingStatus == .signed {
                Task {
                    await self.model.executeTransfer()
                }
            }
        } content: {
            ConfirmationView()
        }
        .sheetPopover(isPresented: .constant(self.model.sendingStatus == .loading || self.model.sendingStatus == .success)) {

            Text("Executing your transfer").textTheme(.headlineSmall)
                .onTapGesture {
                    self.model.sendingStatus = .success
                }

            Spacer().frame(height: 32)

            SpinnerView(isComplete: .constant(self.model.sendingStatus == .success))
        }
        .onChange(of: self.model.sendingStatus) {
            // close confirmation sheet on signing
            if self.model.sendingStatus == .signed {
                self.model.showSendingConfirmation = false
            } else if self.model.sendingStatus == .success {
                Task { @MainActor in
                    try await Task.sleep(for: .seconds(1))

                    self.model.showSendingView = false
                }
            }
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
