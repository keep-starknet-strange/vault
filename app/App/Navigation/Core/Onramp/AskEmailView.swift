//
//  AskEmailView.swift
//  Vault
//
//  Created by Charles Lanier on 01/07/2024.
//

import SwiftUI

struct AskEmailView: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage("email") var email: String = ""

    @State private var presentingNextView = false

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("Keep in the loop !")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                Text("Enter your email to receive important updates and confirmations.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .center, spacing: 32) {
                    TextInput("example@domain.com", text: self.$email, shouldFocusOnAppear: true)
                        .keyboardType(.emailAddress)

                    PrimaryButton("Next", disabled: !self.email.isValidEmail) {
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
            AskFullNameView()
        }
    }
}

#Preview {
    NavigationStack {
        AskEmailView()
    }
}
