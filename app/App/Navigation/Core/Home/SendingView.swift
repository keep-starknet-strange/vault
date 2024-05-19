//
//  SendingView.swift
//  Vault
//
//  Created by Charles Lanier on 17/05/2024.
//

import SwiftUI

struct SendingView: View {
    @State private var amount: String = "0"

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                FancyAmount(amount: self.$amount)

                Spacer()

                VStack(spacing: 32) {
                    PrimaryButton("Continue") {
                        // TODO: logic
                    }

                    NumPad(amount: self.$amount)
                }
            }
            .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .defaultBackground()
            .navigationBarItems(
                leading: IconButton {
                    self.presentationMode.wrappedValue.dismiss()
                } icon: {
                    Image(systemName: "xmark")
                        .iconify()
                        .fontWeight(.bold)
                }
            )
            .removeNavigationBarBorder()
        }
    }
}

#Preview {
    SendingView()
}
