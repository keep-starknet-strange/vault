//
//  TransferView.swift
//  Vault
//
//  Created by Charles Lanier on 02/05/2024.
//

import SwiftUI

struct TransferView: View {

    @State var amount: String = ""

    @State var rawPhoneNumber: String = ""

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: 64) {
                AmountInput(amount: $amount)

                TextInput("phone number", text: $rawPhoneNumber)
                    .keyboardType(.phonePad)
            }
            .frame(maxWidth: 250)

            Spacer()

            HStack {
                PrimaryButton("Request") {}
                PrimaryButton("Send") {}
            }
        }
        .padding(16)
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(.all)
        TransferView()
    }
}
