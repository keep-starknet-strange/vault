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
            Spacer()

            VStack(spacing: 128) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .foregroundStyle(.neutral1)
            }
            .padding(.bottom, 32)

            Spacer()

            VStack(spacing: 64) {
                VStack(spacing: 16) {
                    Text("Welcome on Vault")
                        .textTheme(.headlineLarge)

                    Text("Empower Your Assets\nRedefine Control")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                }
                PrimaryButton("Get Started") {
                    presentingNextView = true
                }
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
