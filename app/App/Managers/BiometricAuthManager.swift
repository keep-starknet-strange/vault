//
//  AuthenticationModel.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import Foundation
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()

    func canUseBiometricAuthentication() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticateWithBiometrics(completion: @escaping (Bool, LAError?) -> Void) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate using Face ID or Touch ID") { success, error in
            DispatchQueue.main.async {
                completion(success, error as? LAError)
            }
        }
    }
}
