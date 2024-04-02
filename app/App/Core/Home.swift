//
//  Home.swift
//  Vault
//
//  Created by Charles Lanier on 01/04/2024.
//

import SwiftUI

struct ActivePointView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gradient1B)
                .strokeBorder(Color.background1, lineWidth: 4)
                .frame(width: 16, height: 16)

            // Stroke color and width
            Circle()
                .stroke(Color.accentColor, lineWidth: 1)
                .opacity(0.5)
                .frame(width: 22, height: 22)
        }
    }
}

struct Home: View {
    @State private var activePoint: CGPoint?

    private let STROKE_WIDTH: CGFloat = 5;
    private let gradient = LinearGradient(gradient: Gradient(colors: [.gradient1A, .gradient1B]), startPoint: .leading, endPoint: .trailing)

    var body: some View {
        let data: [CGFloat] = [10, 50, 38, 26, 54, 100, 36, 4, 40, 40]
//        let data: [CGFloat] = [0, 0, 0, 0, 0, 1, 100, 0, 100, 100]

        VStack(alignment: .leading, spacing: 32) {

            // BALANCE

            VStack(alignment: .leading) {

                Text("Total balance")
                    .font(.custom("Montserrat", size: 12))
                    .foregroundStyle(.neutral2)
                    .fontWeight(.medium)

                Group {
                    Text("$")
                        .font(.custom("Montserrat", size: 46))
                        .foregroundStyle(.neutral1)

                    +

                    Text("12,578.")
                        .font(.custom("Montserrat", size: 42))
                        .foregroundStyle(.neutral1)

                    +

                    Text("00")
                        .font(.custom("Montserrat", size: 28))
                        .foregroundStyle(.neutral2)
                }
                .fontWeight(.semibold)
            }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            // GRAPH

            ZStack {

                // Second curve offset
                ZStack {
                    GraphView(data) { path in
                        path
                            .stroke(.background1, lineWidth: 50)
                            .shadow(color: .neutral2, radius: 0, x: 0, y: -0.5)
                            .shadow(color: .neutral2, radius: 0, x: -0.5, y: 0)
                            .shadow(color: .neutral2, radius: 0, x: 0.5, y: 0)
                            .opacity(0.2)
                    }
                    .frame(height: 80)

                    GraphView(data) { path in
                        path
                            .stroke(.background1, lineWidth: 50)
                            .shadow(color: .background1, radius: 0, x: 0, y: 5)
                    }
                    .frame(height: 80)
                }.offset(x: 0, y: -10)

                // First curve offset

                ZStack {
                    GraphView(data) { path in
                        path
                            .stroke(.background1, lineWidth: 25)
                            .shadow(color: .neutral2, radius: 0, x: 0, y: -0.5)
                            .shadow(color: .neutral2, radius: 0, x: -0.5, y: 0)
                            .shadow(color: .neutral2, radius: 0, x: 0.5, y: 0)
                            .opacity(0.5)
                    }
                    .frame(height: 80)

                    GraphView(data) { path in
                        path
                            .stroke(.background1, lineWidth: 25)
                            .shadow(color: .background1, radius: 0, x: 0, y: 5)
                    }
                    .frame(height: 80)
                }.offset(x: 0, y: -5)

                // real curve

                GraphView(data, activePoint: $activePoint) { path in
                    path
                        .stroke(gradient, lineWidth: STROKE_WIDTH)
                        .shadow(color: .accent.opacity(0.7), radius: 4, x: 0, y: 4)
                        .overlay(activePointOverlay())
                }
                .frame(height: 80)
            }
            .padding(EdgeInsets(top: 50, leading: 0, bottom: -16, trailing: 0))

            // DATES

            HStack {
                ForEach(21...28, id: \.self) { day in
                    Text("\(day)")
                        .font(.system(size: 13))
                        .fontWeight(.medium)
                        .foregroundStyle(.neutral2)
                        .frame(maxWidth: .infinity)
                }
            }.padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
        }
    }

    @ViewBuilder
    private func activePointOverlay() -> some View {
        if let activePoint = activePoint {
            ActivePointView().position(activePoint)
        }
    }
}

#Preview {
    ZStack {
        Color.background1.edgesIgnoringSafeArea(.all)
        VStack {
            Home()
            Spacer()
        }
    }
}
