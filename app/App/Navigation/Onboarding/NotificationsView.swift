//
//  FaceIDView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct NotificationView: View {
    @State private var presentingNextView = false
    @State private var biometricAuthFailed = false

    var body: some View {
        OnboardingPage {
            Spacer()

            Notification(text: "Vitalik sent you $32.49")
                .padding(.bottom, 32)

            Spacer()

            VStack(spacing: 64) {
                VStack(spacing: 16) {
                    Text("Stay Updated Instantly")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Notifications to keep track of your account activity effortlessly.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .center, spacing: 16) {
                    PrimaryButton("Enable notifications") {
                        NotificationsManager.shared.registerFromRemoteNotifications { _, _ in
                            presentingNextView = true
                        }
                    }

                    SecondaryButton("Skip for now") {
                        presentingNextView = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            CelebrationView()
        }
    }
}

#Preview {
    NavigationStack {
        NotificationView()
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
