//
//  Placeholder.swift
//  Vault
//
//  Created by Charles Lanier on 03/07/2024.
//

import SwiftUI

struct AnimatePlaceholderModifier: AnimatableModifier {
    @Binding var isLoading: Bool

    @State private var isAnim: Bool = false
    private var center = (UIScreen.main.bounds.width / 2) + 110
    private let animation: Animation = .linear(duration: 1.5)

    init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }

    func body(content: Content) -> some View {
        content
            .background(self.isLoading ? .background3 : .clear)
            .clipShape(RoundedRectangle(cornerRadius: self.isLoading ? 4 : 0))
            .overlay(animView)
    }

    var animView: some View {
        ZStack {
            Color.black.opacity(isLoading ? 0.09 : 0.0)
            Color.background3.mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: .init(colors: [.clear, .white.opacity(0.48), .clear]),
                            startPoint: .top ,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(1.5)
                    .rotationEffect(.init(degrees: 70.0))
                    .offset(x: isAnim ? center : -center)
            )
        }
        .animation(isLoading ? animation.repeatForever(autoreverses: false) : nil, value: isAnim)
        .onAppear {
            guard isLoading else { return }
            isAnim.toggle()
        }
        .onChange(of: isLoading) {
            isAnim.toggle()
        }
    }
}

extension View {
    func animatePlaceholder(isLoading: Binding<Bool>) -> some View {
        self.modifier(AnimatePlaceholderModifier(isLoading: isLoading))
    }
}
