//
//  Error.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

public struct ErrorResponse: Decodable {
    /// Message that usually gives more information about some error
    public let message: String?
}
