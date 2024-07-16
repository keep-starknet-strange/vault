//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct TransferRow: View {

    @EnvironmentObject var model: Model

    @State private var transfer: Transaction

    init(transfer: Transaction) {
        self.transfer = transfer

        print(transfer.to)
    }

    var body: some View {
        let displayedUser = self.transfer.isSending ? transfer.to : transfer.from
        let displayedContact = displayedUser.phoneNumber == nil ?  nil : self.model.contactsMapping[displayedUser.phoneNumber!]?.first

        let dateFormatter = DateFormatter()
        let _ = dateFormatter.dateFormat = "HH:mm"
        let _ = dateFormatter.timeZone = TimeZone.current // Use the user's current timezone
        let formattedDate = dateFormatter.string(from: transfer.date)

        HStack(alignment: .center, spacing: 12) {
            Avatar(salt: displayedUser.address, name: displayedUser.nickname, size: 46, data: displayedContact?.imageData)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayedUser.nickname ?? "UNKNOWN").textTheme(.bodyPrimary)

                Text("\(formattedDate)").textTheme(.subtitle)
            }

            Spacer()

            Text("\(self.transfer.isSending ? "-" : "")$\(self.transfer.amount.toFixed())")
                .fontWeight(self.transfer.isSending ? .regular : .semibold)
                .textTheme(.bodyPrimary)
                .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                .background(self.transfer.isSending ? .transparent : .accent)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }.fixedSize(horizontal: false, vertical: true)
    }
}
