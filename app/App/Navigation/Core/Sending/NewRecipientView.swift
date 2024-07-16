//
//  NewRecipientView.swift
//  Vault
//
//  Created by Charles Lanier on 21/05/2024.
//

import SwiftUI
import PhoneNumberKit

struct NewRecipientView: View {

    @EnvironmentObject private var model: Model

    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var parsedPhoneNumber: PhoneNumber?

    private var parsedName: String {
        self.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            VStack(spacing: 16) {
                TextInput("Name", text: $name, shouldFocusOnAppear: true)

                PhoneInput(phoneNumber: $phoneNumber, parsedPhoneNumber: $parsedPhoneNumber)
            }

            Spacer()

            PrimaryButton("Add", disabled: self.parsedPhoneNumber == nil || self.parsedName.isEmpty) {
                guard let parsedPhoneNumber = self.parsedPhoneNumber else {
                    fatalError("Should be disabled")
                }

                self.model.addContact(
                    name: self.parsedName,
                    phoneNumber: parsedPhoneNumber.rawString()
                ) { contact in
                    // TODO: handle this new contact
                    print(contact)
                    self.dismiss()
                }
            }
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultBackground()
        .navigationBarBackButtonHidden(true)
        .navigationTitle("New Recipient")
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

#if DEBUG
struct NewRecipientViewPreviews : PreviewProvider {

    @StateObject static var model = Model()

    static var previews: some View {
        NavigationStack {
            NewRecipientView()
                .environmentObject(self.model)
        }
    }
}
#endif
