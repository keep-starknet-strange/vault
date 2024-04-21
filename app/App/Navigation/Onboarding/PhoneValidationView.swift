//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneValidationView: View {
    @State private var presentingNextView = false
    @State private var otp = "" {
        didSet {

        }
    }

    let phoneNumber: PhoneNumber!

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("6-digits code", theme: .headline)

                ThemedText("A code has been sent to +\(phoneNumber.countryCode)\(phoneNumber.numberString)", theme: .body)

                OTPInput(otp: $otp, numberOfFields: Constants.registrationCodeDigitsCount)
                    .onChange(of: otp, initial: false) { (_, newValue) in
                        if newValue.count == Constants.registrationCodeDigitsCount {
                            // TODO: Validate OTP
                            presentingNextView = true
                        }
                    }

                Button {} label: {
                    Text("Resend code").foregroundStyle(.accent)
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
    let phoneNumberKit = PhoneNumberKit()

    var phoneNumber: PhoneNumber? {
        do {
            return try phoneNumberKit.parse("612345678", withRegion: "FR")
        } catch {
            return nil
        }
    }

    return NavigationStack {
        PhoneValidationView(phoneNumber: phoneNumber)
    }
}
