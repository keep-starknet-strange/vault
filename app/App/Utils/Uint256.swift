//
//  Uint256.swift
//  Vault
//
//  Created by Charles Lanier on 02/06/2024.
//

import Foundation
import Starknet
import BigInt

public struct Uint256: NumAsHexProtocol {
    public var value: BigUInt

    public static let max = BigUInt(2).power(256)

    public var low: Felt
    public var high: Felt

    public init?(_ exactly: some BinaryInteger) {
        let value = BigUInt(exactly: exactly)

        guard let value, value < Uint256.max else {
            return nil
        }

        let (high, low) = value.quotientAndRemainder(dividingBy: BigUInt(2).power(128))

        self.low = Felt(low)!
        self.high = Felt(high)!

        self.value = value
    }

    public init(clamping: some BinaryInteger) {
        let value = BigUInt(clamping: clamping)

        self.value = value < Uint256.max ? value : Uint256.max - 1

        let (high, low) = value.quotientAndRemainder(dividingBy: BigUInt(2).power(128))

        self.low = Felt(low)!
        self.high = Felt(high)!
    }

    public init?(fromHex hex: String) {
        guard hex.hasPrefix("0x") else { return nil }

        if let value = BigUInt(hex.dropFirst(2), radix: 16) {
            self.init(value)
        } else {
            return nil
        }
    }
}
