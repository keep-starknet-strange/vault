//
//  Background.swift
//  Vault
//
//  Created by Charles Lanier on 14/05/2024.
//

import SwiftUI

struct DefaultBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(.background1)
    }
}

extension View {
    func defaultBackground() -> some View {
        self.modifier(DefaultBackgroundModifier())
    }
}
