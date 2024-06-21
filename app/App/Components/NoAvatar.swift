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

    var colors: (Color, Color) {
        switch self {
        case .s1:
            return (.vPurple, .vPurpleA50)

        case .s2:
            return (.vGreen, .vGreenA50)

        case .s3:
            return (.vLime, .vLimeA50)

        case .s4:
            return (.vPink, .vPinkA50)

        case .s5:
            return (.vOrange, .vOrangeA50)

        case .s6:
            return (.vBlue, .vBlueA50)
        }
    }

    var fillColor: Color { .accentColor2 }
}

struct NoAvatar: View {
    let salt: NoAvatarSalt
    let name: String

    init(salt: String?, name: String) {
        let saltInt = Int(salt?.bytes.last ?? 0) % NoAvatarSalt.allCases.count
        self.salt = NoAvatarSalt(rawValue: saltInt) ?? .s1
        self.name = name
    }

    var body: some View {
        let (strokeColor, fillColor) = self.salt.colors

        Capsule()
            .fill(fillColor)
            .strokeBorder(strokeColor, lineWidth: 1)
            .frame(width: 42, height: 42)
            .overlay() {
                Text(name.initials.uppercased())
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundStyle(strokeColor)
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
