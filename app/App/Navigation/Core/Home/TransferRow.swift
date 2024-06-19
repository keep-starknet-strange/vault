//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct TransferRow: View {
    @State private var transfer: Transaction

    init(transfer: Transaction) {
        self.transfer = transfer
    }

    var body: some View {
        let displayedUser = self.transfer.isSending ? transfer.to : transfer.from

        let dateFormatter = DateFormatter()
        let _ = dateFormatter.dateFormat = "HH:mm"
        let _ = dateFormatter.timeZone = TimeZone.current // Use the user's current timezone
        let formattedDate = dateFormatter.string(from: transfer.date)

        HStack(spacing: 12) {
            // TODO: use Avatar component
            if let avatarUrl = displayedUser.avatarUrl {
                AsyncImage(
                    url: URL(string: avatarUrl),
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 42, height: 42)
                            .scaledToFit()
                    },
                    placeholder: {
                        ProgressView()
                    }
                )
                .clipShape(Circle())
            } else {
                NoAvatar(name: displayedUser.address == nil ? "?" : displayedUser.nickname)
            }

            VStack(alignment: .leading) {
                Text(displayedUser.nickname).textTheme(.bodyPrimary)

                Spacer()

                Text("\(formattedDate)").textTheme(.subtitle)
            }
            .padding(.vertical, 6)

            Spacer()

            Text("\(self.transfer.isSending ? "-" : "")$\(self.transfer.amount.toFixed())")
                .fontWeight(self.transfer.isSending ? .regular : .semibold)
                .textTheme(.bodySecondary)
                .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                .background(self.transfer.isSending ? .transparent : .accent)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }.fixedSize(horizontal: false, vertical: true)
    }
}
