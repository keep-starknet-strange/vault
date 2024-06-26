//
//  Recipient.swift
//  Vault
//
//  Created by Charles Lanier on 22/05/2024.
//

import Foundation
import Contacts
import UIKit
import Starknet
import BigInt

enum AddressOrPhoneNumber {
    case address(String)
    case phoneNumber(String)
}

struct Recipient: Identifiable {
    var id = UUID()
    var name: String
    var addressOrPhone: AddressOrPhoneNumber
    var imageData: Data?

    init(name: String, address: String, imageData: Data? = nil) {
        self.name = name
        self.addressOrPhone = .address(address)
        self.imageData = imageData
    }

    init(name: String, phoneNumber: String, imageData: Data? = nil) {
        self.name = name
        self.addressOrPhone = .phoneNumber(phoneNumber)
        self.imageData = imageData
    }

    var phoneNumber: String? {
        switch self.addressOrPhone {
        case .address:
            return nil

        case .phoneNumber(let phoneNumber):
            return phoneNumber
        }
    }

    // addr utils

    var address: Felt? {
        switch self.addressOrPhone {
        case .address(let address):
            return Felt(fromHex: address)

        case .phoneNumber(let phoneNumber):
            guard let phoneNumberFelt = Felt.fromShortString(phoneNumber) else {
                return nil
            }

            // TODO: remove this extra step after nonce support
            guard let phoneNumberHex = Felt.fromShortString(phoneNumberFelt.toHex())?.toHex().dropFirst(2) else {
                return nil
            }

            guard let phoneNumberBytes = BigUInt(phoneNumberHex, radix: 16)?.serialize().bytes else {
                return nil
            }

            return StarknetContractAddressCalculator.calculateFrom(
                classHash: Constants.Starknet.blankAccountClassHash,
                calldata: [],
                salt: starknetKeccak(on: phoneNumberBytes),
                deployerAddress: Constants.Starknet.vaultFactoryAddress
            )
        }

    }
}
