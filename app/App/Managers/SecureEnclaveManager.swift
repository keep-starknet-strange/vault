//
//  SecureEnclaveManager.swift
//  Vault
//
//  Created by Charles Lanier on 28/04/2024.
//

import Foundation

struct PublicKey {
    var x: Data
    var y: Data

    var debugDescription: String {
        return "{ x: \(self.x.toHex()), y: \(self.y.toHex()) }"
    }
}

struct Signature {
    var r: Data
    var s: Data

    var debugDescription: String {
        return "{ r: \(self.r.toHex()), s: \(self.s.toHex()) }"
    }
}

class SecureEnclaveManager {

    static let shared = SecureEnclaveManager()

    static let privateKeyLabel = "com.vault.keys.privateKey"

    // MARK: Public

    public func generateKeyPair() throws -> PublicKey? {
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

    public func sign(message: Data) throws -> Signature {
        let privateKey = try self.getPrivateKey()

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw "Error obtaining public key from private key."
        }

        // extract public key data
        guard let parsedPublicKey = self.parse(publicKey: publicKey) else {
            throw "Error parsing public key."
        }

        print("Public key: \(publicKey)\n")
        print("Public key: \(parsedPublicKey.debugDescription)\n")

        // signature
        var hash = "04c659dac4479d23f29a8b7c44e30c87e6f0d662a40b25007eebfaeaa1cb086c"
        guard let signature = self.sign(hash: Data(hex: hash)!, with: privateKey) else {
            throw "Error signing hash."
        }

        print("Hash: 0x\(hash)")
        print("Signature: \(signature.debugDescription)")

        // signature
        hash = "0601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a"
        guard let signature = self.sign(hash: Data(hex: hash)!, with: privateKey) else {
            throw "Error signing hash."
        }

        print("Hash: 0x\(hash)")
        print("Signature: \(signature.debugDescription)")

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

    private func sign(hash: Data, with privateKey: SecKey) -> Signature? {
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

    private func parse(publicKey: SecKey) -> PublicKey? {
        var error: Unmanaged<CFError>?

        if let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? {
            return PublicKey(
                x: publicKeyData[1..<33],
                y: publicKeyData[33..<65]
            )
        } else {
            if let error = error {
                print("Failed to extract public key data: \(error.takeRetainedValue() as Error)")
            }
            return nil
        }
    }

    private func parse(signature signatureData: Data) -> Signature {
        let rLength = Int(signatureData[3]) - 1
        let sLength = Int(signatureData[6 + rLength]) - 1
        let rOffset = 5
        let sOffset = 8 + rLength

        return Signature(
            r: signatureData[rOffset..<(rOffset + rLength)],
            s: signatureData[sOffset..<(sOffset + sLength)]
        )
    }
}
