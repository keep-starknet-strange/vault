//
//  AskBirthDateView.swift
//  Vault
//
//  Created by Charles Lanier on 01/07/2024.
//

import SwiftUI

struct AskBirthDateView: View {

    @Environment(\.dismiss) var dismiss

    @AppStorage("birthDate") var birthDateTimestamp: TimeInterval = 0

    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
    @State private var presentingNextView = false

    private var maxAge = Calendar.current.date(byAdding: .year, value: -18, to: Date())!

    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 64) {
                VStack(alignment: .center, spacing: 24) {
                    Text("Verify Your Age")
                        .textTheme(.headlineLarge)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Enter your age to complete your profile.")
                        .textTheme(.headlineSubtitle)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                DatePicker(
                    "",
                    selection: self.$birthDate,
                    in: ...maxAge,
                    displayedComponents: .date
                )
                    .datePickerStyle(.graphical)

                PrimaryButton("Next") {
                    self.birthDateTimestamp = self.birthDate.timeIntervalSince1970
                    self.presentingNextView = true
                }
            }

            Spacer()
        }
        .padding(EdgeInsets(top: 64, leading: 16, bottom: 32, trailing: 16))
        .defaultBackground()
        .navigationBarItems(
            leading: IconButton {
                self.dismiss()
            } icon: {
                Image(systemName: "chevron.left")
                    .iconify()
                    .fontWeight(.bold)
            }
        )
        .removeNavigationBarBorder()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $presentingNextView) {
            AskHomeAddressView()
        }
    }
}

#Preview {
    NavigationStack {
        AskBirthDateView()
    }
}
