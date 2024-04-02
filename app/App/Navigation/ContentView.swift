//
//  ContentView.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settingsModel = SettingsModel()

    init() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .background1
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }

    var body: some View {
        NavigationStack {
//            OnboardingView()
            Home()
        }
        .environmentObject(settingsModel)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
