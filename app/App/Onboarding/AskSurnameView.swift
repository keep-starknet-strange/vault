//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct AskSurnameView: View {
    @State private var presentingNextView = false
    @State private var surname = ""

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("A Personalized Touch", theme: .headline)

                ThemedText("Introduce yourself with your surname. Change it anytime.", theme: .body)

                TextInput("Surname", text: $surname)
            }

            Spacer()

            PrimaryButton("Next", disabled: surname.isEmpty) {
                presentingNextView = true
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            FaceIDView()
        }
    }
}

#Preview {
    NavigationStack {
        AskSurnameView()
    }
}
