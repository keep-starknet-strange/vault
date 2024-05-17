//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct AskSurnameView: View {
    @EnvironmentObject private var settingsModel: SettingsModel

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
                    TextInput("Surname", text: $settingsModel.surname, shouldFocusOnAppear: true)

                    PrimaryButton("Next", disabled: settingsModel.surname.isEmpty) {
                        presentingNextView = true
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
