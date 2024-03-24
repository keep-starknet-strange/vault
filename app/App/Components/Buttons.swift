//
//  Buttons.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

/// MARK: Primary button

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.accent)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let height: CGFloat = 52

    let text: String
    let disabled: Bool
    let action: (() -> Void) /// use closure for callback

    init(_ text: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) { /// call the closure here
            Text(text)
                .font(.custom("Montserrat", size: 17))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: height)
                .foregroundColor(.background1)
        }
        .buttonStyle(PrimaryButtonStyle())
        .opacity(disabled ? 0.5 : 1)
        .disabled(disabled)
    }
}

/// MARK: Secondary button

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.transparent)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButton: View {
    let height: CGFloat = 52

    let text: String
    let disabled: Bool
    let action: (() -> Void) /// use closure for callback

    init(_ text: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) { /// call the closure here
            Text(text)
                .font(.custom("Montserrat", size: 17))
                .fontWeight(.semibold)
                .frame(minHeight: height)
                .foregroundColor(.accent)
        }
        .buttonStyle(SecondaryButtonStyle())
        .opacity(disabled ? 0.5 : 1)
        .disabled(disabled)
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        VStack {
            Spacer()
            PrimaryButton("Enabled") {}
            PrimaryButton("Disabled", disabled: true) {}
            Spacer()
            SecondaryButton("Enabled") {}
            SecondaryButton("Disabled", disabled: true) {}
            Spacer()
        }.padding(16)
    }
}
