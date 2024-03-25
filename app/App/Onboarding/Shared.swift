//
//  Shared.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

struct OnboardingPage<Content>: View where Content : View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack {
            content()
        }
        .toolbar(.hidden)
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 32, trailing: 16))
        .background(.background1)
    }
}
