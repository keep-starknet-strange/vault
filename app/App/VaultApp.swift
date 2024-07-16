//
//  VaultApp.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

@main
struct VaultApp: App {

    @StateObject private var model = Model()
    @StateObject private var txHistoryModel: PaginationModel<TransactionHistory> = PaginationModel(threshold: 7, pageSize: 15)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.model)
                .environmentObject(self.txHistoryModel)
        }
    }
}
