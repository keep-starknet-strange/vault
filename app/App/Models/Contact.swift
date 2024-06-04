//
//  Contact.swift
//  Vault
//
//  Created by Charles Lanier on 22/05/2024.
//

import Foundation
import Contacts
import Combine
import UIKit

struct Contact: Identifiable {
    var id = UUID()
    var name: String
    var phone: String
    var imageData: Data?
}
