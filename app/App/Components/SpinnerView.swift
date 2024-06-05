//
//  SpinnerView.swift
//  Vault
//
//  Created by Charles Lanier on 30/04/2024.
//

import SwiftUI

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.5))
        path.addLine(to: CGPoint(x: rect.maxX * 0.4, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        return path
    }
}

struct SpinnerView: View {

    @State private var isSpinning = false
    @State private var isTrimming = false

    @Binding var isComplete: Bool {
        didSet {
            self.isTrimming = false
        }
    }

    var body: some View {
        ZStack {
            VStack {
                Circle()
                    .trim(from: 0.0,to: self.isComplete ? 1 : self.isTrimming ? 0.05 : 0.6)
                    .stroke(.accent, style: StrokeStyle(lineWidth: 5.0,lineCap: .round,lineJoin:.round))
                    .frame(width: 48, height: 48)
                    .animation(.easeIn(duration: 1.5).repeatForever(autoreverses: true), value: self.isTrimming)
                    .animation(.linear(duration: 0.3), value: self.isComplete)
                    .onAppear {
                        self.isTrimming = true
                        self.isSpinning = true
                    }
            }
            .rotationEffect(Angle(degrees: isSpinning ? 360 : 0))
            .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isSpinning)

            CheckmarkShape()
                .trim(from: 0, to: isComplete ? 1 : 0)
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 20)
                .offset(y: 1)
                .foregroundColor(.accent)
                .animation(.easeIn(duration: 0.2).delay(0.3), value: isComplete)

        }
    }
}

#Preview {
    struct Preview: View {

        @State var isComplete = false

        var body: some View {
            SpinnerView(isComplete: $isComplete)
                .background(.background1)
                .onTapGesture {
                    // Simulate the completion of the task
                    self.isComplete = true
                }
        }
    }

    return Preview()
}
