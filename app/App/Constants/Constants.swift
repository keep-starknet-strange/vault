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
        static private let vaultFactoryAddresses = [
            StarknetChainId.main.value: Felt("0x410da9af28e654fa93354430841ce7c5f0c2c17cc92971fb23d3d4f826d9834"),
            StarknetChainId.sepolia.value: Felt("0x33498f0d9e6ebef71b3d8dfa56501388cfe5ce96cba81503cd8572be92bd77c"),
        ]
        static let vaultFactoryAddress: Felt = Self.vaultFactoryAddresses[AppConfiguration.Starknet.starknetChainId.value]!

        static private let usdcAddresses = [
            StarknetChainId.main.value: Felt("0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8"),
            StarknetChainId.sepolia.value: Felt("0x07ab0b8855a61f480b4423c46c32fa7c553f0aac3531bbddaa282d86244f7a23"),
        ]
        static let usdcAddress: Felt = Self.usdcAddresses[AppConfiguration.Starknet.starknetChainId.value]!

        static let blankAccountClassHash = Felt("0x1fa186ff7ea06307ded0baa1eb7648afc43618b92084da1110a9c0bd2b6bf56");
    }
}
