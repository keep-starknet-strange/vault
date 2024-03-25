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
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("Stay Updated Instantly", theme: .headline)

                ThemedText("Notifications to keep track of your account activity effortlessly.", theme: .body)
            }

            Spacer()

            Notification(text: "Vitalik sent you $32.49")

            Spacer()

            VStack(alignment: .center, spacing: 16) {
                SecondaryButton("Skip for now") {
                    presentingNextView = true
                }
                PrimaryButton("Enable notifications") {
                    NotificationsManager.shared.registerFromRemoteNotifications { _, _ in
                        presentingNextView = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            AccessCodeView()
        }
    }
}

#Preview {
    NavigationStack {
        NotificationView()
    }
}
