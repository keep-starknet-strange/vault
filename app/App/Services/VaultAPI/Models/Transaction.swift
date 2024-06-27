//
//  Transactions.swift
//  Vault
//
//  Created by Charles Lanier on 19/06/2024.
//

import Foundation

public struct RawTransactionUser: Decodable {
    public let nickname: String?
    public let contract_address: String?
    public let phone_number: String?
}

public struct RawTransaction: Decodable {
    public let transaction_timestamp: String
    public let amount: String
    public let from: RawTransactionUser
    public let to: RawTransactionUser
    public let senderBalance: String
    public let recipientBalance: String
}
