//
//  EarnView.swift
//  Vault
//
//  Created by Charles Lanier on 07/05/2024.
//

import SwiftUI

struct EarnView: View {
    var body: some View {
        VStack {
            Text("Start Earning yield !").textTheme(.headlineLarge)
            Text("Coming soon").textTheme(.subtitle)
        }
    }
}

#Preview {
    ZStack {
        Color.background1.ignoresSafeArea()
        EarnView()
    }
}
