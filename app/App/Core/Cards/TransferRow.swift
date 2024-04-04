//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct TransferRow: View {
    @State private var transfer: Transfer
    @State private var me: User

    init(transfer: Transfer, me: User) {
        self.transfer = transfer
        self.me = me
    }

    var body: some View {
        let isSpeding = transfer.from.address == self.me.address
        let displayedUser = isSpeding ? transfer.to : transfer.from

        let dateFormatter = DateFormatter()
        let _ = dateFormatter.dateFormat = "HH:mm"
        let _ = dateFormatter.timeZone = TimeZone.current // Use the user's current timezone
        let formattedDate = dateFormatter.string(from: transfer.date)

        HStack(spacing: 12) {
            if let avatarUrl = displayedUser.avatarUrl {
                AsyncImage(
                    url: URL(string: avatarUrl),
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 42, height: 42).scaledToFit()
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 99))
            } else {
                Capsule()
                    .fill(.accent.opacity(0.5))
                    .strokeBorder(.accent, lineWidth: 1)
                    .frame(width: 42, height: 42)
                    .overlay() {
                        Text(displayedUser.username.first?.description.uppercased() ?? "")
                            .font(.custom("Montserrat", size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(.accent)
                    }
            }

            VStack(alignment: .leading) {
                Text(displayedUser.username)
                    .font(.custom("Montserrat", size: 17))
                    .fontWeight(.medium)
                    .foregroundStyle(.neutral1)

                Spacer()

                Text("\(formattedDate)")
                    .font(.custom("Montserrat", size: 12))
                    .foregroundStyle(.neutral2)
            }
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

            Spacer()

            Text("\(isSpeding ? "-" : "")$\(transfer.amount.toFixed())")
                .font(.system(size: 17))
                .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                .if(isSpeding) { view in
                    view
                        .foregroundStyle(.neutral1)
                }
                .if(!isSpeding) { view in
                    view
                        .foregroundStyle(.background1)
                        .fontWeight(.semibold)
                        .background(.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
        }.fixedSize(horizontal: false, vertical: true)
    }
}
