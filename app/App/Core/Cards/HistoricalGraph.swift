//
//  HistoricalGraph.swift
//  Vault
//
//  Created by Charles Lanier on 02/04/2024.
//

import SwiftUI

struct ActivePointView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.gradient1B)
                .strokeBorder(Color.neutral1, lineWidth: 2)
                .frame(width: 14, height: 14)

            // Stroke color and width
            Circle()
                .stroke(.gradient1B, lineWidth: 1)
                .opacity(0.5)
                .frame(width: 22, height: 22)
        }
    }
}

struct HistoricalGraph: View {
    @State private var activePoint: CGPoint?

    private let STROKE_WIDTH: CGFloat = 5;

    var body: some View {
        let data: [CGFloat] = [10, 50, 38, 26, 54, 100, 36, 4, 40, 40]
//        let data: [CGFloat] = [0, 0, 0, 0, 0, 1, 100, 0, 100, 100]

        VStack(alignment: .leading, spacing: 40) {

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
                        .stroke(Constants.gradient1, lineWidth: STROKE_WIDTH)
                        .shadow(color: .background1.opacity(0.2), radius: 3, x: 0, y: 3)
                        .shadow(color: .accent.opacity(0.7), radius: 10, x: 0, y: 10)
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
        HistoricalGraph()
    }
}
