//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct PhoneValidationView: View {
    @State private var presentingNextView = false
    @State private var accessCode = ""

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("6-digits code", theme: .headline)

                ThemedText("A code has been sent to +33612345678", theme: .body)
            }

            Spacer()

            PrimaryButton("Start") {
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
        PhoneValidationView()
    }
}
