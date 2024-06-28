//
//  BalanceView.swift
//  Vault
//
//  Created by Charles Lanier on 14/05/2024.
//

import SwiftUI

struct BalanceView: View {

    @Binding var balance: Amount?

    var body: some View {
        let fixedBalance = self.balance?.toFixed() ?? "0.00"
        let splittedBalance = fixedBalance.components(separatedBy: ".")
        let integerPart = splittedBalance[0]
        let decimalPart = splittedBalance[1]

        HStack(spacing: 4) {
            Text("$")
                .font(.custom("Sofia Pro", size: 32))
                .textTheme(.hero)

            HStack(alignment: .bottom, spacing: 0) {
                Text("\(integerPart).")
                    .font(.custom("Sofia Pro", size: 64))
                    .textTheme(.hero)

                Text("\(decimalPart)")
                    .font(.custom("Sofia Pro", size: 36))
                    .foregroundStyle(.neutral2)
                    .textTheme(.hero)
                    .padding(.bottom, 6)
            }
        }
    }
}

#Preview {
    BalanceView(balance: .constant(Amount.usdc(from: 456.18))).defaultBackground()
}
