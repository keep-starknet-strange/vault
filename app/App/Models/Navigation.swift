//
//  NavigationManager.swift
//  Vault
//
//  Created by Charles Lanier on 06/04/2024.
//

import Foundation
import NotificationCenter

enum Tab: Int, CaseIterable{
    case payments = 0
    case budget
    case earn

    var iconName: String {
        switch self {
        case .payments:
            return "Payments"
        case .budget:
            return "Wallet"
        case .earn:
            return "Earning"
        }
    }

    var displayName: String {
        switch self {
        case .payments:
            return "Transfer"
        case .budget:
            return "Budget"
        case .earn:
            return "Earn"
        }
    }
}
