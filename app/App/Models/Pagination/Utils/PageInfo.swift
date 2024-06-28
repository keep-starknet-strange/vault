//
//  PageInfo.swift
//  Vault
//
//  Created by Charles Lanier on 20/06/2024.
//

import Foundation

public struct PageInfo {
    let hasNext: Bool
    let startCursor: String?
    let endCursor: String?

    public static let `default`: Self = Self(hasNext: true, startCursor: nil, endCursor: nil)
}
