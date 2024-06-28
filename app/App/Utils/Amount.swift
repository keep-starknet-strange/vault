//
//  Amount.swift
//  Vault
//
//  Created by Charles Lanier on 05/06/2024.
//

import Foundation
import BigInt

struct Amount: Hashable {
    var value = Uint256(clamping: 0)
    var decimals: UInt8

    private var decimalPlaces: BigUInt {
        return BigUInt(10).power(Int(self.decimals))
    }

    private var doubleDecimalPlaces: Double {
        return pow(10.0, Double(self.decimals))
    }

    static private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US") // Set locale to US
        formatter.roundingMode = .halfEven

        return formatter
    }()

    // MARK: - Init

    public init?(from: Double, decimals: UInt8) {
        self.decimals = decimals

        // Shift the decimal by multiplying with 10^n
        let shiftedValue = from * self.doubleDecimalPlaces

        // Check if shiftedValue is an integer
        guard shiftedValue.truncatingRemainder(dividingBy: 1.0) == 0 else {
            print("Result is not an integer after shifting")
            return nil
        }

        self.value = Uint256(clamping: BigUInt(shiftedValue))
    }

    public init?<S: StringProtocol>(from: S, decimals: UInt8, radix: Int) {
        self.decimals = decimals

        guard let value = BigUInt(from, radix: radix) else {
            print("Cannot convert to BigUint")
            return nil
        }

        self.value = Uint256(clamping: value)
    }

    // MARK: - Formatters

    public func toFixed(_ digits: Int = 2) -> String {
        let formatter = Self.formatter

        formatter.maximumFractionDigits = digits
        formatter.minimumFractionDigits = digits

        let (interger, decimals) = self.value.value.quotientAndRemainder(dividingBy: self.decimalPlaces)

        let doubleValue = Double(interger) + Double(decimals) / self.doubleDecimalPlaces

        return formatter.string(from: NSNumber(value: doubleValue))!
    }
}

extension Amount {

    static func usdc(from: Double) -> Self? {
        return Self(from: from, decimals: Constants.usdcDecimals)
    }

    static func usdc(from: String) -> Self? {
        return Self(from: from, decimals: Constants.usdcDecimals, radix: 10)
    }

    static func usdc(fromHex hex: String) -> Self? {
        guard hex.hasPrefix("0x") else { return nil }

        return Self(from: hex.dropFirst(2), decimals: Constants.usdcDecimals, radix: 16)
    }
}
