//
//  FancyAmount.swift
//  Vault
//
//  Created by Charles Lanier on 17/05/2024.
//

import SwiftUI

struct FancyAmount: View {
    @Binding var amount: String

    var body: some View {
        let splittedAmount = amount.components(separatedBy: ",")
        let shouldDisplayComma = splittedAmount.count > 1

        HStack(spacing: 4) {
            Text("$")
                .font(.custom("Sofia Pro", size: 32))
                .textTheme(.hero)

            HStack(alignment: .bottom, spacing: 0) {
                Text("\(splittedAmount.first!)\(shouldDisplayComma ? "," : "")")
                    .font(.custom("Sofia Pro", size: 64))
                    .textTheme(.hero)

                Text("\(shouldDisplayComma ? splittedAmount.last! : "")")
                    .foregroundStyle(.neutral2)
                    .font(.custom("Sofia Pro", size: 64))
                    .textTheme(.hero)
            }
        }
    }
}

#Preview {
    VStack {
        FancyAmount(amount: .constant("123,45"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .defaultBackground()
}
