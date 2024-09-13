//
//  Icon.swift
//  Vault
//
//  Created by Charles Lanier on 19/05/2024.
//

import SwiftUI

extension Image {
    public func iconify() -> some View {
        self
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
