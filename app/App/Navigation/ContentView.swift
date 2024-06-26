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
        if !self.model.isProperlyConfigured {
            ErrorView()
        } else if self.model.isOnboarded {
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
            // TODO: avoid code duplication
            .sheet(isPresented: self.$model.showRequestingConfirmation) {
                if self.model.sendingStatus == .signed {
                    Task {
                        await self.model.executeTransfer()
                    }
                }
            } content: {
                ConfirmationView()
            }
            .sheetPopover(isPresented: .constant((self.model.sendingStatus == .loading || self.model.sendingStatus == .success) && !self.model.showSendingView)) {

                Text("Executing your transfer").textTheme(.headlineSmall)

                Spacer().frame(height: 32)

                SpinnerView(isComplete: .constant(self.model.sendingStatus == .success))
            }
            .onChange(of: self.model.sendingStatus) {
                // close confirmation sheet on signing
                if self.model.sendingStatus == .signed {
                    self.model.showRequestingConfirmation = false
                } else if self.model.sendingStatus == .success {
                    Task { @MainActor in
                        try await Task.sleep(for: .seconds(1))

                        self.model.sendingStatus = .none
                    }
                }
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
