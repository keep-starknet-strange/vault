//
//  ContentView.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var model: Model

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
        if self.model.isOnboarded {
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
            .onOpenURL { incomingURL in
                #if DEBUG
                print("App was opened via URL: \(incomingURL)")
                #endif

                self.model.handleDeepLink(incomingURL)
            }
            .addSendingConfirmation(isPresented: self.$model.showRequestingConfirmation) {
                self.model.sendingStatus = .none
            }
        } else {
            NavigationStack {
                OnboardingView()
            }
        }
    }
}

#Preview {
    struct ContentViewPreviews: View {

        @StateObject var model = Model()

        var body: some View {
            ContentView()
                .environmentObject(self.model)
        }
    }

    return ContentViewPreviews()
}
