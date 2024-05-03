//
//  Data+Hex.swift
//  Vault
//
//  Created by Charles Lanier on 30/04/2024.
//

import Foundation
import BigInt

extension Data {
    func toHex() -> String {
        return "0x\(String(BigUInt(self), radix: 16))"
    }
}
