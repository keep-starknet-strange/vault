//
//  Constants.swift
//  Vault
//
//  Created by Charles Lanier on 02/04/2024.
//

import Foundation
import SwiftUI

struct Constants {
    static let usdcDecimals = 6
    static let usdcDecimalPlaces: Double = pow(10, Double(usdcDecimals))

    static let gradient1 = Gradient(colors: [.gradient1A, .gradient1B])
    static let linearGradient1 = LinearGradient(
        gradient: Self.gradient1,
        startPoint: .leading,
        endPoint: .trailing
    )

    static let registrationCodeDigitsCount = 6
}
