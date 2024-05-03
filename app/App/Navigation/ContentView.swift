//
//  ContentView.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var registrationModel: RegistrationModel
    @StateObject private var settingsModel = SettingsModel()
    @StateObject private var navigationModel = NavigationModel()

    init() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .background1
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UITabBar.appearance().isHidden = true

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .white
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accentColor)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(Color.accentColor)]

        UITabBar.appearance().standardAppearance = tabBarAppearance

        // init vault API models

        let vaultService = VaultService()

        self._registrationModel = StateObject(wrappedValue: RegistrationModel(vaultService: vaultService))
    }

    var body: some View {
        if settingsModel.isOnboarded {
            ZStack(alignment: .bottom) {
                TabView(selection: $navigationModel.selectedTab) {
                    NavigationStack {
                        HomeView().edgesIgnoringSafeArea(.bottom)
                    }
                    .tag(Tab.accounts)
                    .toolbarBackground(.hidden, for: .tabBar)

                    NavigationStack {
                        TransferView().edgesIgnoringSafeArea(.bottom)
                    }
                    .tag(Tab.transfer)

                    NavigationStack {
                        BudgetView().edgesIgnoringSafeArea(.bottom)
                    }
                    .tag(Tab.budget)
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .environmentObject(settingsModel)
                .preferredColorScheme(.dark)

                CustomTabbar(selectedTab: $navigationModel.selectedTab)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        } else {
            NavigationStack {
                OnboardingView()
            }
            .environmentObject(settingsModel)
            .environmentObject(registrationModel)
            .preferredColorScheme(.dark)
        }
    }
}

#Preview {
    ContentView()
}
