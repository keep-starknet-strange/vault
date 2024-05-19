//
//  NavigationBar.swift
//  Vault
//
//  Created by Charles Lanier on 19/05/2024.
//

import SwiftUI

struct NavigationBarModifier: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()

        DispatchQueue.main.async {
            if let navigationController = viewController.navigationController {
                let appearance = UINavigationBarAppearance()

                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .clear
                appearance.shadowColor = .clear
                navigationController.navigationBar.standardAppearance = appearance
                navigationController.navigationBar.scrollEdgeAppearance = appearance
            }
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

extension View {
    func removeNavigationBarBorder() -> some View {
        self.background(NavigationBarModifier())
    }
}
