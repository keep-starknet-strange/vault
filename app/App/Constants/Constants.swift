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

    static let usdcDecimals: UInt8 = 6

    static let gradient1 = Gradient(colors: [.gradient1A, .gradient1B])
    static let linearGradient1 = LinearGradient(
        gradient: Self.gradient1,
        startPoint: .leading,
        endPoint: .trailing
    )

    static let registrationCodeDigitsCount = 6

    // MARK: ENV

    static let vaultBaseURL: URL? = {
        guard let urlString = ProcessInfo.processInfo.environment["VAULT_API_BASE_URL"],
              let url = URL(string: urlString) else {
            return nil
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

    // MARK: STARKNET

    struct Starknet {
        static let blankAccountClassHash = Felt("0x022d51f548b95dda56852e1e3211ebdcc623637794baf768afff33807f8c4563");
        static let vaultFactoryAddress = Felt("0x8dabd7ce1da04fada30dc43aa90dee1861d62f0575601b19feaf80f801938e");
        static let usdcAddress = Felt("0x07ab0b8855a61f480b4423c46c32fa7c553f0aac3531bbddaa282d86244f7a23")
    }
}
