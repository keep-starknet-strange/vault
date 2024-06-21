//
//  Buttons.swift
//  Vault
//
//  Created by Charles Lanier on 20/03/2024.
//

import SwiftUI

// MARK: Primary button

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.accent)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let height: CGFloat = 54

    let text: String
    let disabled: Bool
    let action: () -> Void

    init(_ text: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .textTheme(.button)
                .padding(.top, 2)
                .frame(maxWidth: .infinity, minHeight: height)
        }
        .buttonStyle(PrimaryButtonStyle())
        .opacity(disabled ? 0.5 : 1)
        .disabled(disabled)
    }
}

// MARK: Secondary button

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.transparent)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButton: View {
    let height: CGFloat = 42

    let text: String
    let disabled: Bool
    let action: () -> Void

    init(_ text: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundStyle(.accent)
                .textTheme(.button)
                .frame(minHeight: height)
                .foregroundColor(.accent)
        }
        .buttonStyle(SecondaryButtonStyle())
        .opacity(disabled ? 0.5 : 1)
        .disabled(disabled)
    }
}

// MARK: Icon button

enum IconButtonSize {
    case medium
    case large
    case custom(CGFloat, CGFloat)

    var buttonSize: CGFloat {
        switch self {
        case .medium:
            return 36

        case .large:
            return 64

        case .custom(let buttonSize, _):
            return buttonSize
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .medium:
            return 12

        case .large:
            return 20

        case .custom(_, let iconSize):
            return iconSize
        }
    }
}

enum IconButtonPriority {
    case primary
    case secondary

    var background: Color {
        switch self {
        case .primary:
            return .accent

        case .secondary:
            return .background2
        }
    }
}

struct IconButtonStyle: ButtonStyle {
    let priority: IconButtonPriority

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(self.priority.background)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButton<Icon>: View where Icon : View {
    let size: IconButtonSize
    let priority: IconButtonPriority
    let icon: Icon
    let action: () -> Void

    init(
        size: IconButtonSize = .medium, 
        priority: IconButtonPriority = .secondary,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.icon = icon()
        self.size = size
        self.action = action
        self.priority = priority
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                HStack {
                    self.icon
                        .frame(width: self.size.iconSize, height: self.size.iconSize)
                        .foregroundStyle(.neutral1)
                }
                .frame(width: self.size.buttonSize, height: self.size.buttonSize)
            }
            .buttonStyle(IconButtonStyle(priority: self.priority))
        }
    }

    @ViewBuilder func withText(_ text: String) -> some View {
        self.modifier(IconButtonWithTextModifier(text: text))
    }
}

struct IconButtonWithTextModifier: ViewModifier {
    var text: String

    func body(content: Content) -> some View {
        VStack(spacing: 10) {
            content
                .preferredColorScheme(.dark)
                .background(.background1)

            Text(self.text).textTheme(.buttonIcon)
        }
    }
}

// MARK: TabItem

struct TabItemButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed || selected ? .neutral1 : .neutral2)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: Noop

struct NoopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
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

            HStack {
                IconButton(size: .large) {} icon: {
                    Image("Gear").iconify()
                }
                .withText("Settings")

                IconButton(size: .large) {} icon: {
                    Image("FaceID").iconify()
                }
                .withText("Face ID")
            }

            Spacer()

            HStack {
                IconButton {} icon: {
                    Image(systemName: "xmark")
                        .iconify()
                        .fontWeight(.bold)
                }
                IconButton {} icon: {
                    Image(systemName: "chevron.down")
                        .iconify()
                        .fontWeight(.bold)
                        .padding(.top, 4)
                }
            }
        }.padding(16)
    }
}
