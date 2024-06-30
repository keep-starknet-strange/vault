//
//  Container.swift
//  Vault
//
//  Created by Charles Lanier on 19/05/2024.
//

import Foundation

struct Container<T: Identifiable>: Identifiable {
    let id = UUID()

    var elements: [T]

    init(_ elements: [T]) {
        self.elements = elements
    }
}
