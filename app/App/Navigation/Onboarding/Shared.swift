//
//  Shared.swift
//  Vault
//
//  Created by Charles Lanier on 22/03/2024.
//

import SwiftUI

struct OnboardingPage<Content>: View where Content : View {

    @Binding var loading: Bool

    let content: Content

    init(isLoading: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.content = content()
        self._loading = isLoading
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        self._loading = .constant(false)
    }

    var body: some View {
        ZStack {
            VStack {
                content
            }
            .toolbar(.hidden)
            .padding(EdgeInsets(top: 64, leading: 16, bottom: 32, trailing: 16))
            .defaultBackground()

            if loading {
                ZStack {
                    Color.background1
                        .opacity(0.5)
                        .ignoresSafeArea()

                    SpinnerView()
                }
            }
        }
    }
}
