//
//  Configuration.swift
//  Vault
//
//  Created by Charles Lanier on 18/06/2024.
//

import Foundation
import Starknet

enum AppConfiguration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }

    enum API {
        static var baseURL: URL {
            let base: String = try! AppConfiguration.value(for: "API_BASE_URL")
            return URL(string: "https://" + base)!
        }
    }

    enum Misc {
        static var privateKeyLabel: String {
            try! AppConfiguration.value(for: "PRIVATE_KEY_LABEL")
        }
    }

    enum Starknet {
        static var starknetChainId: StarknetChainId {
            let networkName: String = try! AppConfiguration.value(for: "SN_NETWORK")
            return StarknetChainId(fromNetworkName: networkName)
        }
    }
}
