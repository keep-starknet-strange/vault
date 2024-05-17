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

//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isLoading = false
//            completion(.success(Void()))
//        }

        vaultService.getOTP(phoneNumber: phoneNumber.rawString()) { result in
            self.isLoading = false
            completion(result)
        }
    }

    func confirmRegistration(
        phoneNumber: PhoneNumber,
        otp: String,
        publicKey: PublicKey,
        completion: @escaping (Result<String, Error>
    ) -> Void) {
        self.isLoading = true

//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.isLoading = false
//            completion(.success("0xdead"))
//        }

        vaultService.verifyOTP(phoneNumber: phoneNumber.rawString(), otp: otp, publicKey: publicKey) { result in
            self.isLoading = false
            completion(result)
        }
    }
}
