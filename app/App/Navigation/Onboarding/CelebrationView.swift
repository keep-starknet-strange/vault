//
//  FaceIDView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import ConfettiSwiftUI

struct CelebrationView: View {

    @AppStorage("isOnboarded") var isOnboarded: Bool = false

    @State private var presentingNextView = false
    @State private var confetti = 0

    var body: some View {
        OnboardingPage {
            Spacer()

            Image(.creditCard)
                .resizable()
                .scaledToFit()
                .padding(24)
                .confettiCannon(counter: $confetti, num: 100, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 250)
                .onAppear() {
                    self.confetti += 1
                }
                .padding(.bottom, 32)

            Spacer()

            VStack(spacing: 64) {
                VStack(spacing: 16) {
                    Text("That’s it ! You are all set")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)

                    Text("You're now part of a 100% mobile, flexible banking revolution. Enjoy the instant transactions, sub-accounts for easier saving, and much more.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton("Start exploring") {
                    isOnboarded = true
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
