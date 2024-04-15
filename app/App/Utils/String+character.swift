//
//  String+character.swift
//  Vault
//
//  Created by Charles Lanier on 15/04/2024.
//

import SwiftUI

extension String {
    func character(at index: Int) -> String? {
        guard index >= 0 && index < self.count else {
            return nil
        }
        
        return String(self[self.index(self.startIndex, offsetBy: index)])
    }
}
