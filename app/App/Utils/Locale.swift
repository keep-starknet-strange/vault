//
//  Locale.swift
//  Vault
//
//  Created by Charles Lanier on 11/04/2024.
//

import Foundation

extension Locale {
    public var regionOrFrance: Locale.Region {
        return self.region ?? Locale.Region.france
    }
}
