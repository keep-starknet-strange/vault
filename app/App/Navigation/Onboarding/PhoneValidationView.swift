//
//  AskSurnameView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI
import PhoneNumberKit

struct PhoneValidationView: View {

    @EnvironmentObject private var registrationModel: RegistrationModel

    @State private var presentingNextView = false
    @State private var otp = "" {
        didSet {

        }
    }

    let phoneNumber: PhoneNumber!

    var body: some View {
        OnboardingPage(isLoading: $registrationModel.isLoading) {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("6-digits code", theme: .headline)

                ThemedText("A code has been sent to +\(phoneNumber.countryCode)\(phoneNumber.numberString)", theme: .body)

                OTPInput(otp: $otp, numberOfFields: Constants.registrationCodeDigitsCount)
                    .onChange(of: otp, initial: false) { (_, newValue) in
                        if newValue.count == Constants.registrationCodeDigitsCount {
                            do {
                                guard let publicKey = try SecureEnclaveManager.shared.generateKeyPair() else {
                                    throw "Failed to generate public key"
                                }

                                registrationModel.confirmRegistration(phoneNumber: self.phoneNumber, otp: newValue, publicKey: publicKey) { result in
                                    switch result {
                                    case .success(let address):
                                        print(address)
                                        presentingNextView = true

                                    case .failure(let error):
                                        print(error)
                                        // TODO: handle error
                                    }
                                }
                            } catch {
                                // TODO: Handle errors
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

#if DEBUG
struct PhoneValidationViewPreviews : PreviewProvider {

    @StateObject static var registrationModel = RegistrationModel(vaultService: VaultService())

    static let phoneNumberKit = PhoneNumberKit()

    static var phoneNumber: PhoneNumber? {
        do {
            return try self.phoneNumberKit.parse("612345678", withRegion: "FR")
        } catch {
            return nil
        }
    }

    static var previews: some View {
        NavigationStack {
            PhoneValidationView(phoneNumber: self.phoneNumber)
                .environmentObject(self.registrationModel)
        }
    }
}
#endif
