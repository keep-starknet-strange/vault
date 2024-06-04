//
//  VaultApp.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

@main
struct VaultApp: App {

    @StateObject private var model: Model

    init() {
        let vaultService = VaultService()

        self._model = StateObject(wrappedValue: Model(vaultService: vaultService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.model)
        }
    }
}
