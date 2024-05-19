//
//  BalanceView.swift
//  Vault
//
//  Created by Charles Lanier on 14/05/2024.
//

import SwiftUI

struct BalanceView: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("$")
                .font(.custom("Sofia Pro", size: 32))
                .textTheme(.hero)

            HStack(alignment: .bottom, spacing: 0) {
                Text("456.")
                    .font(.custom("Sofia Pro", size: 64))
                    .textTheme(.hero)

                Text("18")
                    .font(.custom("Sofia Pro", size: 36))
                    .foregroundStyle(.neutral2)
                    .textTheme(.hero)
                    .padding(.bottom, 6)
            }
        }
    }
}

#Preview {
    BalanceView()
}
