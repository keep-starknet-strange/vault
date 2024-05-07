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
    let height: CGFloat = 60

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
                .textTheme(.button)
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
    let action: (() -> Void) /// use closure for callback

    init(_ text: String, disabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.disabled = disabled
        self.action = action
    }

    var body: some View {
        Button(action: action) { /// call the closure here
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

// MARK: Capsule button

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.accent)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButton: View {
    let size: CGFloat = 52
    let iconSize: CGFloat = 22

    let text: String
    let icon: ImageResource
    let action: (() -> Void) /// use closure for callback

    init(_ text: String, iconName: String, action: @escaping () -> Void) {
        self.text = text
        self.icon = ImageResource(name: iconName, bundle: Bundle.main)
        self.action = action
    }

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) { /// call the closure here
                HStack {
                    Image(self.icon)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: self.iconSize, height: self.iconSize)
                        .foregroundStyle(.neutral1)
                }
                .frame(width: self.size, height: self.size)
            }
            .buttonStyle(IconButtonStyle())

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

// MARK: Gradient

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.neutral1)
            .background(
                LinearGradient(
                    gradient: configuration.isPressed
                    ? Gradient(colors: [.gradient1B])
                    : Constants.gradient1,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
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

            Button() {} label: {
                Text("Enabled")
                    .textTheme(.button)
                    .padding(16)
            }
            .buttonStyle(GradientButtonStyle())

            Spacer()

            HStack {
                IconButton("Send", iconName: "ArrowUp") {}
                IconButton("Add", iconName: "Plus") {}
            }
        }.padding(16)
    }
}
