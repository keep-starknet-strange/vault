//
//  SendingRecipientView.swift
//  Vault
//
//  Created by Charles Lanier on 20/05/2024.
//

import SwiftUI

struct SendingRecipientView: View {

    @Environment(\.dismiss) var dismiss

    @StateObject private var contactsModel = ContactsModel()

    @State private var presentingNewRecipientView = false
    @State private var presentingSendingAmountView = false
    @State private var selectedContact: Contact?

    var body: some View {
        List() {

            switch self.contactsModel.authorizationStatus {
            case .denied, .notDetermined:
                Section {
                    Button {
                        contactsModel.requestAccess()
                    } label: {
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .fontWeight(.semibold)
                                .foregroundStyle(.accent)
                                .padding(10)
                                .background(
                                    Rectangle()
                                        .fill(.accent.opacity(0.25))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                )
                                .shadow(radius: 10)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Authorize contacts access")
                                    .textTheme(.button)
                                    .padding(.top, 2)

                                Text("Send money instantly and easily to your friends on Vault")
                                    .multilineTextAlignment(.leading)
                                    .textTheme(.subtitle)
                                    .padding(.top, 2)
                            }

                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(.background2)
                    .buttonStyle(PlainButtonStyle())
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(EmptyView())
                .listRowSeparator(.hidden)

            default:
                EmptyView()
            }

            ForEach(
                Array(self.contactsModel.contacts.enumerated()),
                id: \.offset
            ) { index, contact in
                let isFirst = index == 0
                let isLast = index == self.contactsModel.contacts.count - 1

                Button {
                    self.selectedContact = contact
                    self.presentingSendingAmountView = true
                } label: {
                    ContactRow(contact: contact)
                        .padding(16)
                        .background(.background2)
                        .clipShape(
                            .rect(
                                topLeadingRadius: isFirst ? 16 : 0,
                                bottomLeadingRadius: isLast ? 16 : 0,
                                bottomTrailingRadius: isLast ? 16 : 0,
                                topTrailingRadius: isFirst ? 16 : 0
                            )
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(EmptyView())
            }
        }

        // List

        .scrollClipDisabled()
        .scrollContentBackground(.hidden)
        .listStyle(.grouped)

        // Layout

        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultBackground()
        .safeAreaInset(edge: .bottom) {
            EmptyView().frame(height: 32)
        }
        .safeAreaInset(edge: .top) {
            EmptyView().frame(height: 16)
        }

        // Nagivation

        .navigationBarBackButtonHidden(true)
        .navigationTitle("Select recipient")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: IconButton {
                self.dismiss()
            } icon: {
                Image(systemName: "xmark")
                    .iconify()
                    .fontWeight(.bold)
            }
        )
        .removeNavigationBarBorder()

        // Navigation destination

        .navigationDestination(isPresented: self.$presentingNewRecipientView) {
            NewRecipientView()
        }
        .navigationDestination(isPresented: self.$presentingSendingAmountView) {
            SendingAmountView()
        }

//            Button {
//                self.presentingNewRecipientView = true
//            } label: {
//                HStack {
//                    Image(systemName: "plus")
//                        .foregroundStyle(.accent)
//                        .fontWeight(.semibold)
//
//                    Text("Add a recipient")
//                        .foregroundStyle(.accent)
//                        .textTheme(.buttonSmall)
//                }
//                .foregroundStyle(.neutral1)
//                .frame(maxWidth: .infinity, minHeight: 54)
//                .padding(.horizontal, 16)
//                .background(.accent.opacity(0.3))
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
    }
}

#Preview {
    NavigationStack {
        SendingRecipientView()
    }
}
