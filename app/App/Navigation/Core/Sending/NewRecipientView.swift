//
//  NewRecipientView.swift
//  Vault
//
//  Created by Charles Lanier on 21/05/2024.
//

import SwiftUI
import PhoneNumberKit

struct NewRecipientView: View {

    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var parsedPhoneNumber: PhoneNumber?

    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(spacing: 16) {
                TextInput("Name", text: $name, shouldFocusOnAppear: true)

                PhoneInput(phoneNumber: $phoneNumber, parsedPhoneNumber: $parsedPhoneNumber)
            }

            Spacer()

            PrimaryButton("Add", disabled: self.parsedPhoneNumber == nil) {
                // TODO: add recipient
            }
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultBackground()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: IconButton {
                self.dismiss()
            } icon: {
                Image(systemName: "chevron.left")
                    .iconify()
                    .fontWeight(.bold)
                    .padding(.trailing, 2)
            }
        )
    }
}

#Preview {
    NavigationStack {
        NewRecipientView()
    }
}
