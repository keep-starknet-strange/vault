//
//  AddSendingConfirmation.swift
//  Vault
//
//  Created by Charles Lanier on 29/06/2024.
//

import SwiftUI

struct AddSendingConfirmationModifier: ViewModifier {

    @EnvironmentObject var model: Model

    @Binding var isPresented: Bool

    @State var isConfirming = false

    var onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$isPresented) {
                if self.model.sendingStatus == .signed {
                    self.isConfirming = true

                    Task {
                        await self.model.executeTransfer()
                    }
                }
            } content: {
                SendingConfirmationView()
            }
            .sheetPopover(isPresented: .constant((self.model.sendingStatus == .loading || self.model.sendingStatus == .success) && self.isConfirming)) {

                Text("Executing your transfer").textTheme(.headlineSmall)

                Spacer().frame(height: 32)

                SpinnerView(isComplete: .constant(self.model.sendingStatus == .success))
            }
            .onChange(of: self.model.sendingStatus) { newValue in
                if !self.isPresented && !self.isConfirming { return }

                // close confirmation sheet on signing
                if newValue == .signed {
                    self.isPresented = false
                } else if newValue == .success {
                    Task {
                        try await Task.sleep(for: .seconds(1))

                        self.isConfirming = false
                        self.onDismiss()
                    }
                }
            }
    }
}

extension View {
    public func addSendingConfirmation(isPresented: Binding<Bool>, onDismiss: @escaping () -> Void) -> some View {
        return self.modifier(
            AddSendingConfirmationModifier(isPresented: isPresented, onDismiss: onDismiss)
        )
    }
}
