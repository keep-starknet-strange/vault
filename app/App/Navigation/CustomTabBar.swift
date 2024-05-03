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
                    if tab.isLarge {
                        ZStack(alignment: .center) {
                            Capsule()
                                .fill(.accent)
                                .strokeBorder(.accentBorder1, lineWidth: 3)
                                .frame(width: 64, height: 64)

                            Image(icon)
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32,height: 32)
                                .foregroundColor(.neutral1)
                        }.padding(
                            EdgeInsets(top: -20, leading: 0, bottom: 0, trailing: 0)
                        )
                    } else {
                        Image(icon)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25,height: 25)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(TabItemButtonStyle(selected: selectedTab == tab))
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 46)
        .background(.black.opacity(0.3))
        .background(.ultraThinMaterial)
        .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
        .background(EdgeBorder(width: 1, edges: [.top]).foregroundStyle(.border1))
        .padding(EdgeInsets(top: -1, leading: 0, bottom: 0, trailing: 0))
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        TabView(selection: .constant(Tab.accounts)) {
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
        .preferredColorScheme(.dark)

        CustomTabbar(selectedTab: .constant(.accounts))
    }
}
