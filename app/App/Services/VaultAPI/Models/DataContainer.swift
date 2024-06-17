//
//  DataContainer.swift
//  Vault
//
//  Created by Charles Lanier on 14/06/2024.
//

import Foundation

/// All successful responses return this, and contains all
/// the metainformation about the returned chunk.
public struct DataContainer<Results: Decodable>: Decodable {
    public let results: Results
}
