//
//  FaceIDView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import ConfettiSwiftUI

struct CelebrationView: View {
    @EnvironmentObject private var settingsModel: SettingsModel

    @State private var presentingNextView = false
    @State private var confetti = 0

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("That’s it ! You are all set", theme: .headline)

                ThemedText("You're now part of a 100% mobile, flexible banking revolution. Enjoy the instant transactions, sub-accounts for easier saving, and much more.", theme: .body)
            }

            Spacer()

            Image(.creditCard)
                .resizable()
                .scaledToFit()
                .padding(24)
                .confettiCannon(counter: $confetti, num: 100, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 250)
                .onAppear() {
                    self.confetti += 1
                }

            Spacer()

            VStack(alignment: .center, spacing: 16) {
                PrimaryButton("Start exploring") {
                    settingsModel.isOnboarded = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CelebrationView()
    }
}
