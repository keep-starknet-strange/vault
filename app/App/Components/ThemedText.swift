//
//  Text.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

enum TextTheme {
    case hero
    case headlineLarge
    case headlineMedium
    case headlineSmall
    case button
    case buttonSmall
    case bodyPrimary
    case bodySecondary
    case subtitle
    case tabButton(Bool)
}

struct ThemedTextModifier: ViewModifier {
    var theme: TextTheme

    func body(content: Content) -> some View {
        switch (theme) {
        case .hero:
            content
                .font(.custom("Sofia Pro", size: 46))
                .fontWeight(.medium)
                .foregroundStyle(.neutral1)
                .tracking(1.2)

        case .headlineLarge:
            content
                .font(.system(size: 32))
                .fontWeight(.medium)
                .foregroundStyle(.neutral1)
                .tracking(1.2)

        case .headlineMedium:
            content
                .font(.system(size: 20))
                .fontWeight(.medium)
                .foregroundStyle(.neutral1)
                .tracking(1.2)

        case .headlineSmall:
            content
                .font(.system(size: 18))
                .fontWeight(.medium)
                .foregroundStyle(.neutral1)
                .tracking(1.2)

        case .button:
            content
                .font(.custom("Sofia Pro", size: 18))
                .foregroundStyle(.neutral1)
                .fontWeight(.medium)

        case .buttonSmall:
            content
                .font(.system(size: 17))
                .foregroundStyle(.accent)
                .fontWeight(.regular)

        case .bodyPrimary:
            content
                .font(.custom("Sofia Pro", size: 17))
                .foregroundStyle(.neutral1)
                .fontWeight(.regular)

        case .bodySecondary:
            content
                .font(.system(size: 15))
                .foregroundStyle(.neutral1)
                .fontWeight(.regular)

        case .subtitle:
            content
                .font(.system(size: 13))
                .foregroundStyle(.neutral2)
                .fontWeight(.regular)
                .tracking(-0.1)

        case .tabButton(let active):
            content
                .font(.system(size: 10))
                .foregroundStyle(active ? .neutral1 : .neutral2)
                .fontWeight(.medium)
        }
    }
}

extension View {
    func textTheme(_ theme: TextTheme) -> some View {
        self.modifier(ThemedTextModifier(theme: theme))
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        VStack(alignment: .leading, spacing: 16) {
            Text("Hero").textTheme(.hero)
            Text("Hedaline Large").textTheme(.headlineLarge)
            Text("Hedaline Medium").textTheme(.headlineMedium)
            Text("Hedaline Small").textTheme(.headlineSmall)
            Text("Button").textTheme(.button)
            Text("Button Small").textTheme(.buttonSmall)
            Text("Body Primary").textTheme(.bodyPrimary)
            Text("Body Secondary").textTheme(.bodySecondary)
            Text("Subtitle").textTheme(.subtitle)
            Text("Tab button (active)").textTheme(.tabButton(true))
            Text("Tab button (inactive)").textTheme(.tabButton(false))
        }
    }
}
