//
//  Page.swift
//  Vault
//
//  Created by Charles Lanier on 21/06/2024.
//

import Foundation

public protocol Page {

    associatedtype Item: Identifiable

    var info: PageInfo { get set }
    var items: [Item] { get set }
}
