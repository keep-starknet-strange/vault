//
//  ActivityView.swift
//  Vault
//
//  Created by Charles Lanier on 25/06/2024.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: self.activityItems,
            applicationActivities: self.applicationActivities
        )

        // close view on completion
        controller.completionWithItemsHandler = { _, _, _, _ in
            self.isPresented = false
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update action needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: ActivityView

        init(_ parent: ActivityView) {
            self.parent = parent
        }
    }
}
