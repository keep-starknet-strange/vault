//
//  NoAvatar.swift
//  Vault
//
//  Created by Charles Lanier on 22/05/2024.
//

import SwiftUI

struct NoAvatar: View {
    let name: String

    var body: some View {
        Capsule()
            .fill(.accent.opacity(0.5))
            .strokeBorder(.accent, lineWidth: 1)
            .frame(width: 42, height: 42)
            .overlay() {
                Text(name.initials.uppercased())
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .foregroundStyle(.accent)
            }
    }
}

#Preview {
    VStack {
        NoAvatar(name: "Kenny McCormick")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .defaultBackground()
}
