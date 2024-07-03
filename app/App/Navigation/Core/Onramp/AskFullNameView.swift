//
//  AskFullNameView.swift
//  Vault
//
//  Created by Charles Lanier on 01/07/2024.
//

import SwiftUI

struct AskFullNameView: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage("firsName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""

    @State private var presentingNextView = false

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("Confirm your full name")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Please input your full name exactly as it is on your ID. This helps us keep your account secure.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .center, spacing: 32) {
                    VStack(alignment: .center, spacing: 16) {
                        TextInput("John", text: self.$firstName, shouldFocusOnAppear: true)

                        TextInput("Doe", text: self.$lastName)
                    }

                    PrimaryButton("Next", disabled: self.firstName.isEmpty || self.lastName.isEmpty) {
                        self.presentingNextView = true
                    }
                }
            }

            Spacer()
        }
        .padding(EdgeInsets(top: 64, leading: 16, bottom: 32, trailing: 16))
        .defaultBackground()
        .navigationBarItems(
            leading: IconButton {
                self.dismiss()
            } icon: {
                Image(systemName: "chevron.left")
                    .iconify()
                    .fontWeight(.bold)
            }
        )
        .removeNavigationBarBorder()
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $presentingNextView) {
            AskBirthDateView()
        }
    }
}
