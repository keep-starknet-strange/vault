//
//  RegistrationModel.swift
//  Vault
//
//  Created by Charles Lanier on 21/04/2024.
//

import Foundation
import PhoneNumberKit

class RegistrationModel: ObservableObject {

    private var vaultService: VaultService

    init(vaultService: VaultService) {
        self.vaultService = vaultService
    }

    func startRegistration(phoneNumber: PhoneNumber) {
        vaultService.getOTP(phoneNumber: phoneNumber.rawString()) { success in
            print(success)
        }
    }

    func confirmRegistration(phoneNumber: PhoneNumber, otp: String, publicKey: String) {
        vaultService.verifyOTP(phoneNumber: phoneNumber.rawString(), otp: otp, publicKey: publicKey) { address in
            print(address ?? "0xdead")
        }
    }
}
