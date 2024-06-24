//
//  NoAvatar.swift
//  Vault
//
//  Created by Charles Lanier on 22/05/2024.
//

import SwiftUI
import Starknet

enum NoAvatarSalt: Int, CaseIterable {
    case s1 = 0
    case s2 = 1
    case s3 = 2
    case s4 = 3
    case s5 = 4
    case s6 = 5

    var gradient: Gradient {
        switch self {
        case .s1:
            return Gradient(colors: [.vPurple, .vPurpleDarker])

        case .s2:
            return Gradient(colors: [.vGreen, .vGreenDarker])

        case .s3:
            return Gradient(colors: [.vLime, .vLimeDarker])

        case .s4:
            return Gradient(colors: [.vPink, .vPinkDarker])

        case .s5:
            return Gradient(colors: [.vOrange, .vOrangeDarker])

        case .s6:
            return Gradient(colors: [.vBlue, .vBlueDarker])
        }
    }

    var fillColor: Color { .accentColor2 }
}

struct NoAvatar: View {
    let salt: NoAvatarSalt
    let name: String
    let size: CGFloat

    init(salt: String?, name: String, size: CGFloat = Avatar.defaultSize) {
        let saltInt = Int(salt?.bytes.last ?? 0) % NoAvatarSalt.allCases.count
        self.salt = NoAvatarSalt(rawValue: saltInt) ?? .s1
        self.name = name
        self.size = size
    }

    var body: some View {
        let linearGradient = LinearGradient(
            gradient: self.salt.gradient,
            startPoint: .top,
            endPoint: .bottom
        )

        Capsule()
            .fill(linearGradient)
            .frame(width: self.size, height: self.size)
            .overlay() {
                Text(name.initials.uppercased())
                    .font(.system(size: 18))
                    .fontWeight(.medium)
                    .foregroundStyle(.neutral1)
            }
    }
}

#Preview {
    VStack {
        NoAvatar(salt: "1", name: "Kenny McCormick")
        NoAvatar(salt: "2", name: "Kenny McCormick")
        NoAvatar(salt: "3", name: "Kenny McCormick")
        NoAvatar(salt: "4", name: "Kenny McCormick")
        NoAvatar(salt: "5", name: "Kenny McCormick")
        NoAvatar(salt: "6", name: "Kenny McCormick")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .defaultBackground()
}
