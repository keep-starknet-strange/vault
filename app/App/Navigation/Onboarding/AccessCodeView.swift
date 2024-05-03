//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct AccessCodeView: View {
    @State private var presentingNextView = false
    @State private var accessCode = ""

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("Early User Access", theme: .headline)

                ThemedText("To join our exclusive early users, please enter your access code.", theme: .body)

                TextInput("Access Code", text: $accessCode)
            }

            Spacer()

            PrimaryButton("Start", disabled: accessCode.isEmpty) {
                // TODO: Verify access code
                presentingNextView = true
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            AskSurnameView()
        }
    }
}

#Preview {
    NavigationStack {
        AccessCodeView()
    }
}
