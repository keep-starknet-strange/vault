//
//  Amount.swift
//  Vault
//
//  Created by Charles Lanier on 05/06/2024.
//

import Foundation
import BigInt

class Amount {
    var value = Uint256(clamping: 0)
    var decimals: UInt8

    private var decimalPlaces: BigUInt {
        return BigUInt(10).power(Int(self.decimals))
    }

    private var doubleDecimalPlaces: Double {
        return pow(10.0, Double(self.decimals))
    }

    private lazy var formatter: NumberFormatter = {
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

    // MARK: - Formatters

    public func toFixed(_ digits: Int = 2) -> String {
        self.formatter.maximumFractionDigits = digits
        self.formatter.minimumFractionDigits = digits

        let (interger, decimals) = self.value.value.quotientAndRemainder(dividingBy: self.decimalPlaces)

        let doubleValue = Double(interger) + Double(decimals) / self.doubleDecimalPlaces

        return formatter.string(from: NSNumber(value: doubleValue))!
    }
}

class USDCAmount: Amount {
    init?(from: Double) {
        super.init(from: from, decimals: Constants.usdcDecimals)
    }
}
