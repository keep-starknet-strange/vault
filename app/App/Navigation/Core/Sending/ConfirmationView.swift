//
//  ConfirmationView.swift
//  Vault
//
//  Created by Charles Lanier on 04/06/2024.
//

import SwiftUI

struct ConfirmationView: View {

    @EnvironmentObject var model: Model

    @AppStorage("surname") var surname: String = ""

    var body: some View {
        let recipientConact = self.model.recipientContact!
        let usdcAmount = USDCAmount(from: self.model.parsedSendingAmount)!

        VStack {
            Text("Finalize your transfer")
                .textTheme(.headlineSmall)
                .padding(.vertical, 32)

            Spacer().frame(height: 16)

            HStack {
                VStack(spacing: 8) {
                    Avatar(
                        name: surname
                    )

                    Text("You")
                        .foregroundStyle(.neutral1)
                        .fontWeight(.semibold)
                        .textTheme(.subtitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .background(.background3.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer(minLength: 24)

                VStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.neutral1)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.background3, lineWidth: 1)
                )

                Spacer(minLength: 24)

                VStack(spacing: 8) {
                    Avatar(
                        imageData: recipientConact.imageData,
                        name: recipientConact.name
                    )

                    Text(recipientConact.name)
                        .foregroundStyle(.neutral1)
                        .fontWeight(.semibold)
                        .textTheme(.subtitle)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .background(.background3.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer().frame(height: 16)

            HStack {
                Text("Amount")
                    .textTheme(.bodySecondary)

                Spacer()

                Text("$\(usdcAmount.toFixed())")
                    .textTheme(.headlineSmall)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(.background3.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            PrimaryButton("Send") {
                Task {
                    await self.model.signTransfer()
                }
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    struct ConfirmationViewPreviews : View {

        @StateObject var model = {
            let model = Model(vaultService: VaultService())

            model.setRecipient(Contact(name: "Very Long Bobby Name", phone: "+33612345678"))

            return model
        }()

        var body: some View {
            VStack {}
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .defaultBackground()
                .sheet(isPresented: .constant(true)) {
                    ConfirmationView()
                        .environmentObject(model)
                }
        }
    }

    return ConfirmationViewPreviews()
}
