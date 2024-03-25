//
//  Text.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

enum TextTheme {
    case body
    case headline
}

struct ThemedText: View {
    let text: String
    let theme: TextTheme

    init(_ text: String, theme: TextTheme) {
        self.text = text
        self.theme = theme
    }

    var body: some View {
        switch (theme) {
        case .body:
            Text(text)
                .font(.custom("Montserrat", size: 17))
                .foregroundStyle(.neutral1)
                .fontWeight(.medium)
                .tracking(-0.3)

        case .headline:
            Text(text)
                .font(.system(size: 32))
                .fontWeight(.medium)
                .foregroundStyle(.neutral1)
                .tracking(1.36)
        }
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        VStack(alignment: .leading, spacing: 16) {
            ThemedText("Lorem ipsum dolor", theme: .headline)
            ThemedText("Lorem ipsum dolor", theme: .body)
        }
    }
}
