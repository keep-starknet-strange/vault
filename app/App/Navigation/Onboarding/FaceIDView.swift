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
            Spacer()

            Image(.faceID)
                .foregroundStyle(.accent)
                .padding(.bottom, 32)

            Spacer()

            VStack(spacing: 64) {
                VStack(spacing: 16) {
                    Text("Better experience with Face ID")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)

                    Text("Enable Face ID to make your transactions smooth and secure.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                }

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
