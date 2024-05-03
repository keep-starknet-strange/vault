//
//  HTTPURLReponse.swift
//  Vault
//
//  Created by Charles Lanier on 30/04/2024.
//

import Foundation

extension HTTPURLResponse {
    var isSuccessful: Bool {
        return (200..<300).contains(statusCode)
    }
}
