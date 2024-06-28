//
//  VaultPage.swift
//  Vault
//
//  Created by Charles Lanier on 20/06/2024.
//

import Foundation

public struct VaultPage<T: Decodable>: Decodable {
    public let hasNext: Bool
    public let startCursor: String?
    public let endCursor: String?
    public let items: [T]
}
