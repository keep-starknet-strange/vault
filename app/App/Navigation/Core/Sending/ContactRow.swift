//
//  ContactRow.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct ContactRow: View {

    let contact: Recipient

    var body: some View {
        HStack(spacing: 12) {
            Avatar(salt: self.contact.phoneNumber, name: self.contact.name, data: self.contact.imageData)

            VStack(alignment: .leading) {
                Text(self.contact.name)
                    .textTheme(.bodyPrimary)
                    .lineLimit(1)

                Spacer()

                Text(self.contact.phoneNumber ?? "").textTheme(.subtitle)
            }
            .padding(.vertical, 6)

            Spacer()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack {
        ContactRow(contact: Recipient(name: "Kenny McCormick", phoneNumber: "+33612345678"))
        ContactRow(contact: Recipient(name: "Kenny McCormick But with a very long name", phoneNumber: "+33612345678"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .defaultBackground()
}
