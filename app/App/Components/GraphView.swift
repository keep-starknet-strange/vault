//
//  GraphView.swift
//  Vault
//
//  Created by Charles Lanier on 02/04/2024.
//

import SwiftUI

struct GraphView<Content>: View where Content : View {
    // @Binding
    private var activePoint: Binding<CGPoint?>?

    let data: [CGFloat]
    let transform: (Path) -> Content

    init?(
        _ data: [CGFloat],
        activePoint: Binding<CGPoint?>? = nil,
        transform: @escaping (Path) -> Content
    ) {
        if data.count < 2 {
            return nil
        }

        self.activePoint = activePoint
        self.data = data
        self.transform = transform
    }

    private func getStepWidth(geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width / CGFloat(data.count - 2)
    }

    private func coordYFor(index: Int, geometry: GeometryProxy) -> CGFloat {
        geometry.size.height - geometry.size.height * data[index] / (data.max() ?? 1)
    }

    private func pointForIndex(_ index: Int, step: CGFloat, geometry: GeometryProxy) -> CGPoint {
        return CGPoint(
            x: step * (CGFloat(index) - 0.5),
            y: coordYFor(index: index, geometry: geometry)
        )
    }

    private func quadCurvedPath(in geometry: GeometryProxy) -> Path {
        var path = Path()
        let step = getStepWidth(geometry: geometry)

        let firstPoint = pointForIndex(0, step: step, geometry: geometry)
        path.move(to: firstPoint)

        var previousPoint = firstPoint
        var oldControlPoint = previousPoint

        for index in 1..<data.count {
            let currentPoint = pointForIndex(index, step: step, geometry: geometry)
            var nextPoint: CGPoint?
            if index < data.count - 1 {
                nextPoint = pointForIndex(index + 1, step: step, geometry: geometry)
            }

            let newControlPoint = controlPointForPoints(previousPoint, currentPoint, next: nextPoint) ?? currentPoint

            path.addCurve(to: currentPoint, control1: oldControlPoint, control2: newControlPoint)

            previousPoint = currentPoint
            oldControlPoint = antipodalFor(point: newControlPoint, center: currentPoint)
        }
        return path
    }

    private func antipodalFor(point: CGPoint, center: CGPoint) -> CGPoint {
        let newX = 2 * center.x - point.x
        let newY = 2 * center.y - point.y

        return CGPoint(x: newX, y: newY)
    }

    private func midPointForPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }

    private func controlPointForPoints(_ p1: CGPoint, _ p2: CGPoint, next p3: CGPoint?) -> CGPoint? {
        guard let p3 = p3 else {
            return nil
        }

        let leftMidPoint = midPointForPoints(p1, p2)
        let rightMidPoint = midPointForPoints(p2, p3)
        var controlPoint = midPointForPoints(leftMidPoint, antipodalFor(point: rightMidPoint, center: p2))

        controlPoint.x += (p2.x - p1.x) * 0.2

        if p1.y < p2.y {
            controlPoint.y = max(p1.y, controlPoint.y)
        } else {
            controlPoint.y = min(p1.y, controlPoint.y)
        }

        return midPointForPoints(controlPoint, antipodalFor(point: p2, center: controlPoint))
    }

    var body: some View {
        GeometryReader { geometry in
            let step = getStepWidth(geometry: geometry)
            let drawPath = quadCurvedPath(in: geometry)

            self.transform(
                Path { path in
                    path.addPath(drawPath)
                }
            )
            .if(self.activePoint != nil) { view in
                view.gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // we avoid the last point which is offscreen
                            let activeIndex = min(
                                Int(ceil(value.location.x / step)),
                                data.count - 1
                            );

                            self.activePoint?.wrappedValue = pointForIndex(activeIndex, step: step, geometry: geometry)
                        }
                )
            }

        }
    }
}
