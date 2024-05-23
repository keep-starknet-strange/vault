//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct AskSurnameView: View {

    @AppStorage("surname") var surname: String = ""

    @State private var presentingNextView = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("Let's get started !").textTheme(.headlineLarge)

                    Text("Introduce yourself with your surname. Change it anytime.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .center, spacing: 32) {
                    TextInput("Surname", text: self.$surname, shouldFocusOnAppear: true)

                    PrimaryButton("Next", disabled: surname.isEmpty) {
                        self.presentingNextView = true
                    }
                }
            }

            Spacer()
        }
        .navigationDestination(isPresented: $presentingNextView) {
            PhoneRequestView()
        }
    }
}

#Preview {
    NavigationStack {
        AskSurnameView()
    }
}
