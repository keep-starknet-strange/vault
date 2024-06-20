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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(self.model)
        }
    }
}
