//
//  Amount.swift
//  Vault
//
//  Created by Charles Lanier on 02/04/2024.
//

import Foundation

class USDCAmount {

    // MARK: Properties

    private let rawAmount: Double
    private var amount: Double {
        get {
            return self.rawAmount / Constants.usdcDecimalPlaces
        }
    }

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US") // Set locale to US
        formatter.roundingMode = .halfEven

        return formatter
    }()

    // MARK: Initializer

    init(_ rawAmount: Double) {
        self.rawAmount = rawAmount

    }

    // MARK: Methods

    func toFixed(_ digits: Int = 2) -> String {
        self.formatter.maximumFractionDigits = digits
        self.formatter.minimumFractionDigits = digits

        return formatter.string(from: NSNumber(value: self.amount)) ?? "\(self.amount)"
    }
}
