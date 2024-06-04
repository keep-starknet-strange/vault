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
                        .onChange(of: otp, initial: false) { (_, newValue) in
                            if newValue.count == Constants.registrationCodeDigitsCount {
                                do {
                                    guard let publicKey = try SecureEnclaveManager.shared.generateKeyPair() else {
                                        throw "Failed to generate public key"
                                    }

                                    self.model.confirmRegistration(
                                        phoneNumber: self.phoneNumber,
                                        otp: newValue,
                                        publicKeyX: publicKey.x.toHex(),
                                        publicKeyY: publicKey.y.toHex()
                                    ) { result in
                                        switch result {
                                        case .success(let address):

                                            #if DEBUG
                                            print(address)
                                            #endif

                                            // save address
                                            self.address = address

                                            // next view
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
}

#if DEBUG
struct PhoneValidationViewPreviews : PreviewProvider {

    @StateObject static var model = Model(vaultService: VaultService())

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
