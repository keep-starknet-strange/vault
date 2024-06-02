//
//  RegistrationModel.swift
//  Vault
//
//  Created by Charles Lanier on 21/04/2024.
//

import Foundation
import PhoneNumberKit

class RegistrationModel: ObservableObject {

    @Published var isLoading = false

    private var vaultService: VaultService

    init(vaultService: VaultService) {
        self.vaultService = vaultService
    }

    func startRegistration(phoneNumber: PhoneNumber, completion: @escaping (Result<Void, Error>) -> Void) {
        self.isLoading = true

        vaultService.getOTP(phoneNumber: phoneNumber.rawString()) { result in
            self.isLoading = false
            completion(result)
        }
    }

    func confirmRegistration(
        phoneNumber: PhoneNumber,
        otp: String,
        publicKeyX: String,
        publicKeyY: String,
        completion: @escaping (Result<String, Error>
    ) -> Void) {
        self.isLoading = true

        vaultService.verifyOTP(
            phoneNumber: phoneNumber.rawString(),
            otp: otp,
            publicKeyX: publicKeyX,
            publicKeyY: publicKeyY
        ) { result in
            self.isLoading = false
            completion(result)
        }
    }
}
