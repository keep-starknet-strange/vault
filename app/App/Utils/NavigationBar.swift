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
                let topAppearance = UINavigationBarAppearance()
                let scrolledAppearance = UINavigationBarAppearance()

                topAppearance.configureWithOpaqueBackground()
                topAppearance.backgroundColor = .clear
                topAppearance.backgroundImage = UIImage()
                topAppearance.shadowImage = UIImage()
                topAppearance.shadowColor = .clear

                scrolledAppearance.configureWithOpaqueBackground()
                scrolledAppearance.backgroundColor = .clear
                scrolledAppearance.backgroundImage = UIImage()
                scrolledAppearance.shadowImage = UIImage()
                scrolledAppearance.shadowColor = .clear

//                navigationController.navigationBar.standardAppearance = scrolledAppearance
                navigationController.navigationBar.scrollEdgeAppearance = topAppearance
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
