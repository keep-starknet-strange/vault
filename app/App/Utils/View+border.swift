//
//  View+border.swift
//  Vault
//
//  Created by Charles Lanier on 04/04/2024.
//

import SwiftUI

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        background(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
