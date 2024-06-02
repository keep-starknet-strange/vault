//
//  TransferModel.swift
//  Vault
//
//  Created by Charles Lanier on 02/06/2024.
//

import SwiftUI

class TransferModel: ObservableObject {

    @Published var recipientPhoneNumber: String?

    func setPhoneNumber(_ phoneNumber: String) {
        self.recipientPhoneNumber = phoneNumber
    }
}
