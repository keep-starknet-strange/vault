//
//  Configuration.swift
//  Vault
//
//  Created by Charles Lanier on 18/06/2024.
//

import Foundation

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
        static var baseURL: URL? {
            do {
                let base: String = try AppConfiguration.value(for: "API_BASE_URL")

                return URL(string: "https://" + base)
            } catch {
                return nil
            }
        }
    }
}
