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

    @EnvironmentObject private var starknetModel: StarknetModel
    @EnvironmentObject private var transferModel: TransferModel

    @State private var amount: String = "0"

    private var parsedAmount: Float {
        // Replace the comma with a dot
        let amount = self.amount.replacingOccurrences(of: ",", with: ".")

        // Check if the string ends with a dot and append a zero if true
        // Convert the final string to a Float
        return Float(amount.hasSuffix(".") ? "\(amount)0" : amount) ?? 0
    }

    var body: some View {
        VStack {
            Spacer()

            FancyAmount(amount: self.$amount)

            Spacer()

            VStack(spacing: 32) {
                PrimaryButton("Continue", disabled: self.parsedAmount <= 0) {
                    Task {
                        try await starknetModel.sendUSDC(to: transferModel.recipientPhoneNumber!)
                    }
                }

                NumPad(amount: self.$amount)
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
    }
}

#Preview {
    NavigationStack {
        SendingView()
    }
}
