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

            VStack {
                Image(.textLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                Text("Empower Your Assets\nRedefine Control")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.neutral2)
                    .font(.custom("Montserrat", size: 17))
                    .fontWeight(.medium)
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
