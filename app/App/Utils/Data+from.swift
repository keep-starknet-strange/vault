//
//  String+Data.swift
//  Vault
//
//  Created by Charles Lanier on 28/04/2024.
//

import Foundation

extension Data {

    init?(hex: String) {
        let cleanString = hex.filter { $0 != " " && $0 != "\n" } // Remove spaces and newlines if any
        guard cleanString.count % 2 == 0 else {
            print("Hex string must have an even number of digits")
            return nil
        }

        var data = Data()
        var currentIndex = cleanString.startIndex

        while currentIndex != cleanString.endIndex {
            let nextIndex = cleanString.index(currentIndex, offsetBy: 2)
            if nextIndex <= cleanString.endIndex {
                let byteString = cleanString[currentIndex..<nextIndex]
                if let byte = UInt8(byteString, radix: 16) {
                    data.append(byte)
                } else {
                    print("Error: String contains invalid hexadecimal numbers")
                    return nil
                }
                currentIndex = nextIndex
            } else {
                break
            }
        }

        self = data
    }
}
