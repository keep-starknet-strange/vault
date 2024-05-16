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
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("Early User Access").textTheme(.headlineLarge)

                    Text("To join our exclusive early users, please enter your access code.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .center, spacing: 32) {
                    TextInput("Access Code", text: $accessCode, shouldFocusOnAppear: true)

                    PrimaryButton("Start", disabled: accessCode.isEmpty) {
                        // TODO: Verify access code
                        presentingNextView = true
                    }
                }
            }

            Spacer()
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
