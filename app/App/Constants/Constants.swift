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

    // MARK: ENV

    static let vaultBaseURL: URL = {
        guard let urlString = ProcessInfo.processInfo.environment["VAULT_API_BASE_URL"],
              let url = URL(string: urlString) else {
            fatalError("Vault API Base URL not configured properly.")
        }
        return url
    }()

    // MARK: ICONS

    struct Icons {
        static let arrowUp = Self.renderIcon("ArrowUp")
        static let arrowDown = Self.renderIcon("ArrowDown")
        static let plus = Self.renderIcon("Plus")

        static private func renderIcon(_ name: String) -> any View {
            return Image(name)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

