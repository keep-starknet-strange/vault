//
//  VaultError.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

public enum VaultError: Error {
    case encoding
    case decoding
    case unknown
    case server(message: String)
}
