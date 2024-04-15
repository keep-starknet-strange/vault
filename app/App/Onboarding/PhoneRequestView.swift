//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneRequestView: View {
    @State private var presentingNextView = false
    @State private var phoneNumber = ""
    @State private var parsedPhoneNumber: PhoneNumber?

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("Let's get started !", theme: .headline)

                ThemedText("Enter your phone number. We will send you a confirmation code.", theme: .body)

                PhoneInput(phoneNumber: $phoneNumber, parsedPhoneNumber: $parsedPhoneNumber)
            }

            Spacer()

            VStack(alignment: .center, spacing: 16) {
//                SecondaryButton("Already have an account? Log in") {
//                    presentingNextView = true
//                }
                PrimaryButton("Sign up", disabled: self.parsedPhoneNumber == nil) {
                    presentingNextView = true
                }
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            PhoneValidationView(phoneNumber: parsedPhoneNumber)
        }
    }
}

#Preview {
    NavigationStack {
        PhoneRequestView()
    }
}
