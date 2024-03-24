//
//  FaceIDView.swift
//  Vault
//
//  Created by Charles Lanier on 21/03/2024.
//

import SwiftUI

struct FaceIDView: View {
    @State private var presentingNextView = false
    @State private var biometricAuthFailed = false

    var body: some View {
        OnboardingPage {
            VStack(alignment: .leading, spacing: 24) {
                ThemedText("Better experience with Face ID", theme: .headline)

                ThemedText("Enable Face ID to make your transactions smooth and secure.", theme: .body)
            }

            Spacer()

            Image(.faceID).foregroundStyle(.accent)

            Spacer()

            VStack(alignment: .center, spacing: 16) {
                PrimaryButton("Set up Face ID") {
                    BiometricAuthManager.shared.authenticateWithBiometrics { success, error in
                        if !success {
                            switch error?.code {
                            case .userCancel: break

                            default:
                                biometricAuthFailed = true;
                            }
                        } else {
                            presentingNextView = true
                        }
                    }
                }
                .alert(isPresented: $biometricAuthFailed) {
                    Alert(
                        title: Text("Face ID or Touch ID not available"),
                        message: Text("Please, ensure your device supports biometric features and that you've allowed Vault to use them.")
                    )
                }
            }
        }
        .navigationDestination(isPresented: $presentingNextView) {
            NotificationView()
        }
    }
}

#Preview {
    NavigationStack {
        FaceIDView()
    }
}
