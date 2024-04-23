//
//  PhoneNumber+Parse.swift
//  Vault
//
//  Created by Charles Lanier on 23/04/2024.
//

import Foundation
import PhoneNumberKit

extension PhoneNumber {
    
    func rawString() -> String {
        return "+\(self.countryCode)\(self.numberString.filter("0123456789.".contains))"
    }
}
