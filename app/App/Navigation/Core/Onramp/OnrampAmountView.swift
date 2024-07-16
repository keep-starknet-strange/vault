//
//  OnrampAmountView.swift
//  Vault
//
//  Created by Charles Lanier on 01/07/2024.
//

import SwiftUI

struct OnrampAmountView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var model: Model

    @State private var presentingNextView = false

    private var hexAmount: String {
        Amount.usdc(from: self.model.parsedAmount)?.value.toHex() ?? "0x0"
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                FancyAmount(amount: self.$model.amount)

                VStack {
                    if
                        let totalUsd = self.model.onRampTotalUsd,
                        let totalUsdDouble = Double(totalUsd)
                    {
                        Text("$\(String(format: "%.2f", totalUsdDouble - self.model.parsedAmount)) Fees").textTheme(.headlineSubtitle)
                    }
                }
                .frame(minWidth: 100, minHeight: 24)
                .redacted(reason: self.model.isLoading ? .placeholder : [])
                .animatePlaceholder(isLoading: self.$model.isLoading)
            }

            Spacer()

            VStack(spacing: 32) {
                PrimaryButton("Next", disabled: self.model.onRampQuoteId == nil) {
                    self.presentingNextView = true
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
                Image(systemName: "xmark")
                    .iconify()
                    .fontWeight(.bold)
            }
        )
        .removeNavigationBarBorder()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Select Amount")
        .navigationDestination(isPresented: $presentingNextView) {
            OnrampStripeView()
        }
        .onChange(of: self.model.amount) {
            self.model.getOnrampQuote()
        }
    }
}

#if DEBUG
struct OnrampAmountViewPreviews : PreviewProvider {

    @StateObject static var model = Model()

    static var previews: some View {
        OnrampAmountView()
            .environmentObject(self.model)
    }
}
#endif
