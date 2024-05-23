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
                topAppearance.backgroundColor = .background1
                topAppearance.shadowColor = .clear

                scrolledAppearance.configureWithOpaqueBackground()
                scrolledAppearance.backgroundColor = .background1
                scrolledAppearance.shadowColor = .background2
//                scrolledAppearance.shadowImage = UIImage.gradientImageWithBounds(
//                    bounds: CGRect( x: 0, y: 0, width: UIScreen.main.scale, height: 16),
//                    colors: [
//                        UIColor.background2.withAlphaComponent(0.5).cgColor,
//                        UIColor.background2.withAlphaComponent(0).cgColor,
//                    ]
//                )

                navigationController.navigationBar.standardAppearance = scrolledAppearance
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
