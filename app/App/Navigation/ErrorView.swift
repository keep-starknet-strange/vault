//
//  ErrorView.swift
//  Vault
//
//  Created by Charles Lanier on 18/06/2024.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        VStack {
            Text("An error has occurred").textTheme(.headlineLarge)
            Text("Please contact our support.").textTheme(.subtitle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .defaultBackground()
    }
}

#Preview {
    ErrorView()
}
