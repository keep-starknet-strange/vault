//
//  SpinnerView.swift
//  Vault
//
//  Created by Charles Lanier on 30/04/2024.
//

import SwiftUI

struct SpinnerView: View {

    @State private var spinnerLength = 0.6
    @State private var degree:Int = 270

    var body: some View {
        Circle()
            .trim(from: 0.0,to: spinnerLength)
            .stroke(.accent, style: StrokeStyle(lineWidth: 5.0,lineCap: .round,lineJoin:.round))
            .rotationEffect(Angle(degrees: Double(degree)))
            .frame(width: 48,height: 48)
            .onAppear {
                withAnimation(Animation.easeIn(duration: 1.5).repeatForever(autoreverses: true)) {
                    spinnerLength = 0.05
                }
                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                    degree = 270 + 360
                }
            }
    }
}

#Preview {
    ZStack {
        SpinnerView()
    }
}
