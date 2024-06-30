//
//  RequestingAmountView.swift
//  Vault
//
//  Created by Charles Lanier on 25/06/2024.
//

import SwiftUI

struct RequestingAmountView: View {

    @Environment(\.dismiss) var dismiss

    @EnvironmentObject private var model: Model

    @State var isShareSheetPresented = false

    private var hexAmount: String {
        Amount.usdc(from: self.model.parsedAmount)?.value.toHex() ?? "0x0"
    }

    var body: some View {
        VStack {
            Spacer()

            FancyAmount(amount: self.$model.amount)

            Spacer()

            VStack(spacing: 32) {
                PrimaryButton("Request", disabled: self.model.parsedAmount <= 0) {
                    self.isShareSheetPresented = true
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
        .sheet(isPresented: self.$isShareSheetPresented) {
            ActivityView(
                activityItems: [
                    "Hello ! Please send me $\(self.model.amount) via vltfinance://request?amount=\(self.hexAmount)&recipientAddress=\(self.model.address)"
                ],
                isPresented: self.$isShareSheetPresented
            )
            .ignoresSafeArea()
            .presentationDragIndicator(.hidden)
            .presentationDetents([.medium, .large])
        }
    }
}

#if DEBUG
struct RequestingAmountViewPreviews : PreviewProvider {

    @StateObject static var model = Model()

    static var previews: some View {
        RequestingAmountView()
            .environmentObject(self.model)
    }
}
#endif
