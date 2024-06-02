//
//  Constants.swift
//  Vault
//
//  Created by Charles Lanier on 02/04/2024.
//

import Foundation
import SwiftUI
import Starknet

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

    static let starknetRpcApiKey: String = {
        guard let apiKey = ProcessInfo.processInfo.environment["STARKNET_RPC_API_KEY"] else {
            fatalError("Starknet RPC API key not configured properly.")
        }

        return apiKey
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

    // MARK: STARKNET

    struct Starknet {
        static let blankAccountClassHash = Felt("0x022d51f548b95dda56852e1e3211ebdcc623637794baf768afff33807f8c4563");
        static let vaultFactoryAddress = Felt("0x060f7dc1dcb936fd9bff710d4a19da3870e611e014b3ceaa662d24ac87221894");
        static let usdcAddress = Felt("0x053b40a647cedfca6ca84f542a0fe36736031905a9639a7f19a3c1e66bfd5080")
    }
}

