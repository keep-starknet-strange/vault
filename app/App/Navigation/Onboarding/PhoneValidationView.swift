//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneValidationView: View {

    @EnvironmentObject private var model: Model

    @AppStorage("starknetMainAddress") private var address: String = "0xdead"

    @State private var presentingNextView = false
    @State private var otp = "" {
        didSet {

        }
    }

    let phoneNumber: PhoneNumber!

    var body: some View {
        OnboardingPage(isLoading: $model.isLoading) {
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("6-digits code").textTheme(.headlineLarge)

                    Text("A code has been sent to +\(phoneNumber.countryCode)\(phoneNumber.numberString.filter { !$0.isWhitespace })")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 32) {
                    OTPInput(otp: $otp, numberOfFields: Constants.registrationCodeDigitsCount)
                        .onChange(of: self.otp) { newValue in
                            if newValue.count == Constants.registrationCodeDigitsCount {
                                self.model.confirmRegistration(phoneNumber: self.phoneNumber, otp: newValue) {
                                    // next view
                                    presentingNextView = true
                                }
                            }
                        }

                    Button {} label: {
                        Text("Resend code").foregroundStyle(.accent)
                    }
                }

                Spacer()
            }
            .navigationDestination(isPresented: $presentingNextView) {
                FaceIDView()
            }
        }
    }
}

#if DEBUG
struct PhoneValidationViewPreviews : PreviewProvider {

    @StateObject static var model = Model()

    static let phoneNumberKit = PhoneNumberKit()

    static var phoneNumber: PhoneNumber? {
        do {
            return try self.phoneNumberKit.parse("6 12 34 56 78", withRegion: "FR")
        } catch {
            return nil
        }
    }

    static var previews: some View {
        NavigationStack {
            PhoneValidationView(phoneNumber: self.phoneNumber)
                .environmentObject(self.model)
        }
    }
}
#endif
