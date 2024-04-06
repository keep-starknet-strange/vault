//
//  NavigationManager.swift
//  Vault
//
//  Created by Charles Lanier on 06/04/2024.
//

import Foundation
import NotificationCenter

enum Tab: Int, CaseIterable{
    case accounts = 0
    case transfer
    case budget

    var iconName: String {
        switch self {
        case .accounts:
            return "Accounts"
        case .transfer:
            return "Transfer"
        case .budget:
            return "Wallet"
        }
    }

    var isLarge: Bool {
        switch self {
        case .transfer:
            return true
        default:
            return false
        }
    }
}

class NavigationModel: ObservableObject {
    @Published var selectedTab: Tab = Tab.accounts

    func openTab(_ tab: Tab) {
        self.selectedTab = tab
    }
}
