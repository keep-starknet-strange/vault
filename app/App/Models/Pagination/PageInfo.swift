//
//  PageInfo.swift
//  Vault
//
//  Created by Charles Lanier on 20/06/2024.
//

import Foundation

public struct PageInfo {
    let hasNext: Bool
    let endCursor: String?

    public static let `default`: Self = Self(hasNext: true, endCursor: nil)
}
