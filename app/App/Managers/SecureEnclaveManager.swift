//
//  SecureEnclaveManager.swift
//  Vault
//
//  Created by Charles Lanier on 28/04/2024.
//

import Foundation
import Starknet

struct P256Signature {
    var r: Uint256
    var s: Uint256
}

class SecureEnclaveManager {

    static let shared = SecureEnclaveManager()

    static let privateKeyLabel = "com.vault.keys.privateKey"

    // MARK: Public

    public func generateKeyPair() throws -> P256PublicKey? {
        // compute private key access rights
        let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryAny],
            nil
        )! // Ignore errors.

        // compute private key attributes
        let attributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrAccessControl: access,
                kSecAttrLabel: Self.privateKeyLabel,
            ],
        ]

        var error: Unmanaged<CFError>?

        // generate private key
        guard let privateKey = SecKeyCreateRandomKey(attributes, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        // get public key from private key
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw "Error obtaining public key from private key."
        }

        // extract public key data
        let parsedPublicKey = self.parse(publicKey: publicKey)

        return parsedPublicKey
    }

    public func sign(hash: Felt) throws -> P256Signature {
        let privateKey = try self.getPrivateKey()

        // Signature
        guard let signature = self.sign(hash: hash.value.serialize(), with: privateKey) else {
            throw "Error signing hash."
        }

        #if DEBUG
        print("Signature: \(signature)")
        #endif

        return signature
    }

    // MARK: Internals

    private func getPrivateKey() throws -> SecKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrLabel as String: Self.privateKeyLabel,
            kSecReturnRef as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw "Failed to retrieve private key" }

        return item as! SecKey
    }

    private func sign(hash: Data, with privateKey: SecKey) -> P256Signature? {
        var error: Unmanaged<CFError>?

        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureDigestX962SHA256,
            hash as CFData,
            &error
        ) as Data? else {
            let errorDescription = error!.takeRetainedValue() as Error
            print("Error signing hash: \(errorDescription)")
            return nil
        }

        return self.parse(signature: signature)
    }

    // MARK: Parsing

    private func parse(publicKey: SecKey) -> P256PublicKey? {
        var error: Unmanaged<CFError>?

        if let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? {
            return P256PublicKey(
                x: Uint256(fromHex: publicKeyData[1..<33].toHex())!,
                y: Uint256(fromHex: publicKeyData[33..<65].toHex())!
            )
        } else {
            if let error = error {
                print("Failed to extract public key data: \(error.takeRetainedValue() as Error)")
            }
            return nil
        }
    }

    private func parse(signature signatureData: Data) -> P256Signature {
        let rLength = Int(signatureData[3]) - 1
        let sLength = Int(signatureData[6 + rLength]) - 1
        let rOffset = 5
        let sOffset = 8 + rLength

        return P256Signature(
            r: Uint256(fromHex: signatureData[rOffset..<(rOffset + rLength)].toHex())!,
            s: Uint256(fromHex: signatureData[sOffset..<(sOffset + sLength)].toHex())!
        )
    }
}
