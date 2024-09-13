//
//  String+character.swift
//  Vault
//
//  Created by Charles Lanier on 15/04/2024.
//

import SwiftUI

extension String {

    var initials: String {
        let words = self.split(separator: " ")

        switch words.count {
        case 0:
            return ""

        case 1:
            return String(words[0].prefix(1))

        default:
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        }
    }

    func character(at index: Int) -> String? {
        guard index >= 0 && index < self.count else {
            return nil
        }
        
        return String(self[self.index(self.startIndex, offsetBy: index)])
    }
}
