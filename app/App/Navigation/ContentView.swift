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
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .neutral1
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: Color.neutral1]

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
                    .tag(Tab.payments)
                    .toolbarBackground(.hidden, for: .tabBar)

                    NavigationStack {
                        BudgetView().edgesIgnoringSafeArea(.bottom)
                    }
                    .tag(Tab.budget)

                    NavigationStack {
                        EarnView().edgesIgnoringSafeArea(.bottom)
                    }
                    .tag(Tab.earn)
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
