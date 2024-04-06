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

    static let gradient1 = LinearGradient(
        gradient: Gradient(colors: [.gradient1A, .gradient1B]),
        startPoint: .leading,
        endPoint: .trailing
    )
}
