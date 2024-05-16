//
//  BudgetView.swift
//  Vault
//
//  Created by Charles Lanier on 06/04/2024.
//

import SwiftUI

struct BudgetView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("$1267").textTheme(.hero)

                    Text("spent this month").textTheme(.subtitle)
                }

                HistoricalGraph().padding(EdgeInsets(top: 0, leading: -16, bottom: 0, trailing: -16))
            }

            Button {
                // TODO: open sheet or new view
            } label: {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "plus")
                        .font(.system(size: 22))
                        .fontWeight(.semibold)
                        .foregroundStyle(.accent)
                        .padding(10)
                        .background(
                            Rectangle()
                                .fill(.neutral1)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )
                        .shadow(radius: 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set up your budget").textTheme(.headlineMedium)
                        Text("Gain peace of mind by organizing your spending.").textTheme(.bodySecondary)
                    }

                    Spacer(minLength: 0)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(16)
            }
            .buttonStyle(GradientButtonStyle())

            Spacer()
        }
        .padding(16)
        .defaultBackground()
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(.all)
        BudgetView()
    }
}
