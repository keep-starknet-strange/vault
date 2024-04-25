//
//  EdgeBorder.swift
//  Vault
//
//  Created by Charles Lanier on 04/04/2024.
//

import SwiftUI

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}
