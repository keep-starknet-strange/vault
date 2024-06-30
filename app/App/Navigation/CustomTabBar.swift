//
//  CustomTabItem.swift
//  Vault
//
//  Created by Charles Lanier on 04/04/2024.
//

import SwiftUI

struct CustomTabbar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                let icon = ImageResource(name: tab.iconName, bundle: Bundle.main)

                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25,height: 25)
                            .frame(maxWidth: .infinity)

                        Text(tab.displayName).textTheme(.tabButton(selectedTab == tab))
                    }
                    .padding(.top, 6)
                }
                .buttonStyle(TabItemButtonStyle(selected: selectedTab == tab))
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 48, maxHeight: 48)
        .background(.background1)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        TabView(selection: .constant(Tab.payments)) {
            HomeView()
                .edgesIgnoringSafeArea(.bottom)
                .toolbarBackground(.hidden, for: .tabBar)
                .tag(0)

            Text("Send")
                .tag(1)

            Text("Budget")
                .tag(2)
        }
        .toolbarBackground(.hidden, for: .navigationBar)

        CustomTabbar(selectedTab: .constant(.payments))
    }
}
