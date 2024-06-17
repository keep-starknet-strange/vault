//
//  VaultResponse.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

/// Top level response for every request to the Vault API
/// Everything in the API seems to be optional, so we cannot rely on having values here
public struct VaultResponse<Response: Decodable>: Decodable {
    /// Whether it was ok or not
    public let status: String?
    /// Message that usually gives more information about some error
    public let message: String?
    /// Requested data
    public let data: DataContainer<Response>?
}
