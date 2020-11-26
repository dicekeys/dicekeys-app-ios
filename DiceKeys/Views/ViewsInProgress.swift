//
//  ViewsInProgress.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct DiceKeyPresent: View {
    let diceKey: DiceKey

    var body: some View {
        DiceKeyView(diceKey: diceKey, showLidTab: true)
    }
}

struct DiceKeyPresentPreview: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct DiceKeyAbsent: View {
    let diceKey: DiceKey

    var body: some View {
        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: true)
    }
}

struct DiceKeyAbsentPreview: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct FunnelView: View {
    let height: CGFloat
    let topWidth: CGFloat
    let bottomWidth: CGFloat
    var bottleneckWidth: CGFloat?
    var bottleneckFractionFromTop: CGFloat?

    let curvature: CGFloat = 0.4

    var invCurvature: CGFloat {
        CGFloat(1) - curvature
    }

    var body: some View {
        Path { path in
            let bottleneckWidth = self.bottleneckWidth ?? (topWidth / 5)

            let centerX = max(topWidth, bottomWidth) / 2

            let topLeft = centerX - topWidth / 2
            let topRight = centerX + topWidth / 2
            let bottomLeft = centerX - bottomWidth / 2
            let bottomRight = centerX + bottomWidth / 2
            let bottleneckLeft = centerX - bottleneckWidth / 2
            let bottleneckRight = centerX + bottleneckWidth / 2

            let top: CGFloat = 0
            let bottom: CGFloat = height

            var  bottleneckY: CGFloat { top + height * ( bottleneckFractionFromTop ?? 0.6 ) }

            path.move(to: CGPoint(x: topLeft, y: top))
            path.addCurve(
                to: CGPoint(x: bottleneckLeft, y: top + bottleneckY),
                control1: CGPoint(x: topLeft, y: top + (bottleneckY - top) * invCurvature ),
                control2: CGPoint(x: bottleneckLeft, y: top + (bottleneckY - top) * curvature)
            )
            path.addCurve(
                to: CGPoint(x: bottomLeft, y: bottom),
                control1: CGPoint(x: bottleneckLeft, y: bottleneckY + (bottom - bottleneckY) * invCurvature),
                control2: CGPoint(x: bottomLeft, y: bottleneckY + (bottom - bottleneckY) * curvature)
            )
            path.addLine(to: CGPoint(x: bottomRight, y: bottom))
            path.addCurve(
                to: CGPoint(x: bottleneckRight, y: bottleneckY),
                control1: CGPoint(x: bottomRight, y: bottleneckY + (bottom - bottleneckY) * curvature),
                control2: CGPoint(x: bottleneckRight, y: bottleneckY + (bottom - bottleneckY) * invCurvature)
            )
            path.addCurve(
                to: CGPoint(x: topRight, y: top),
                control1: CGPoint(x: bottleneckRight, y: top + (bottleneckY - top) * curvature),
                control2: CGPoint(x: topRight, y: top + (bottleneckY - top) * invCurvature )
            )
            path.addLine(to: CGPoint(x: topLeft, y: top))
        } // .fill(Color.blue)
    }
}

struct ViewsInProgress_Previews: PreviewProvider {
    static var previews: some View {
        FunnelView(height: 100, topWidth: 200, bottomWidth: 500)
            .previewLayout(.fixed(width: 500, height: 100))
//        AssemblyInstructions(step: .DropDice)

//        DiceKeyPresent(diceKey: DiceKey.createFromRandom())
    }
}
