//
//  AskHomeAddress.swift
//  Vault
//
//  Created by Charles Lanier on 02/07/2024.
//

import SwiftUI

struct AskHomeAddressView: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage("homeAddress") var homeAddress: String = ""

    @State private var presentingWebView = false

    private var maxAge = Calendar.current.date(byAdding: .year, value: -18, to: Date())!

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("Almost Finished !")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Enter your home address to complete your setup. We’ll take care of the rest.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .center, spacing: 32) {
                    TextInput("Address", text: self.$homeAddress, shouldFocusOnAppear: true)

                    PrimaryButton("Next", disabled: self.homeAddress.isEmpty) {
                        self.presentingWebView = true
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
        .sheet(isPresented: self.$presentingWebView) {
            WebView(url: URL(string: "https://google.com")!)
        }
    }
}

#Preview {
    NavigationStack {
        AskHomeAddressView()
    }
}
