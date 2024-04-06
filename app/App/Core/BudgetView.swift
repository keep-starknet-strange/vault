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

                    Group {
                        Text("$")
                            .font(.custom("Montserrat", size: 46))
                            .kerning(5)

                        +

                        Text("1267")
                            .font(.custom("Montserrat", size: 42))
                            .kerning(0.6)
                    }
                    .foregroundStyle(.neutral1)
                    .fontWeight(.semibold)

                    Text("spent this month")
                        .font(.custom("Montserrat", size: 13))
                        .fontWeight(.medium)
                        .foregroundStyle(.neutral2)
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
                        Text("Set up your budget")
                            .font(.system(size: 20))
                            .fontWeight(.medium)

                        Text("Gain peace of mind by organizing your spending.")
                            .font(.system(size: 15))
                    }

                    Spacer(minLength: 0)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(16)
            }
            .buttonStyle(GradientButtonStyle())

            Spacer()
        }.padding(16)
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(.all)
        BudgetView()
    }
}
