//
//  WelcomeView.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

struct WelcomeView: View {
    @State private var presentingNextView = false

    var body: some View {
        OnboardingPage {
            Image(.welcome)

            Spacer()

            VStack(spacing: 8) {
                Image(.textLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)

                Text("Empower Your Assets\nRedefine Control")
                    .foregroundStyle(.neutral2)
                    .textTheme(.bodyPrimary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryButton("Get Started") {
                presentingNextView = true
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            AccessCodeView()
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
