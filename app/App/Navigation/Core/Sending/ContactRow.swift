//
//  ContactRow.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct ContactRow: View {

    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            Avatar(imageData: self.contact.imageData, name: self.contact.name)

            VStack(alignment: .leading) {
                Text(self.contact.name)
                    .textTheme(.bodyPrimary)
                    .lineLimit(1)

                Spacer()

                Text(self.contact.phone).textTheme(.subtitle)
            }
            .padding(.vertical, 6)

            Spacer()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    VStack {
        ContactRow(contact: Contact(name: "Kenny McCormick", phone: "+33612345678"))
        ContactRow(contact: Contact(name: "Kenny McCormick But with a very long name", phone: "+33612345678"))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .defaultBackground()
}
