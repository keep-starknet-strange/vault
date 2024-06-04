//
//  ContentView.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

struct ContentView: View {

    @AppStorage("isOnboarded") var isOnboarded: Bool = false

    @State private var selectedTab: Tab = Tab.payments

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
    }

    var body: some View {
        if self.isOnboarded {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        HomeView()
                    }
                    .tag(Tab.payments)

                    NavigationStack {
                        BudgetView()
                    }
                    .tag(Tab.budget)

                    NavigationStack {
                        EarnView()
                    }
                    .tag(Tab.earn)
                }
                .edgesIgnoringSafeArea(.bottom)

                CustomTabbar(selectedTab: $selectedTab)
            }
        } else {
            NavigationStack {
                OnboardingView()
            }
        }
    }
}

#Preview {
    ContentView()
}
