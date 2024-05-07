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
            VStack(alignment: .leading, spacing: 24) {
                Text("A Personalized Touch").textTheme(.headlineLarge)

                Text("Introduce yourself with your surname. Change it anytime.").textTheme(.bodyPrimary)

                TextInput("Surname", text: $settingsModel.surname)
            }

            Spacer()

            PrimaryButton("Next", disabled: settingsModel.surname.isEmpty) {
                presentingNextView = true
            }
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
