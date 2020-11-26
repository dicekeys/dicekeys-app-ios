//
//  DiceKeyView.swift
//  
//
//  Created by Stuart Schechter on 2020/11/18.
//

import SwiftUI

private struct DieLidView: View {
    let radius: CGFloat
    let color: Color

    var body: some View {
        return Path { path in
            path.addArc(center: CGPoint(x: radius, y: 0), radius: radius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 180), clockwise: false)
        }
        .fill(color)
        .frame(width: 2 * radius, height: radius)
    }
}

private let fractionOfVerticalSpaceRequiredForTab: CGFloat = 0.1

private struct DiceKeyViewFixedSize: View {
    let diceKey: DiceKey
    let viewSize: CGSize
    let showLidTab: Bool // = false
    let leaveSpaceForTab: Bool// = false
    let diceBoxColor: Color// = Color(red: 0x05 / 0xFF, green: 0x03 / 0xFF, blue: 0x50 / 0xFF)

    var fractionOfVerticalSpaceUsedByTab: CGFloat {
        (leaveSpaceForTab || showLidTab) ? fractionOfVerticalSpaceRequiredForTab : 0
    }

    var fractionOfVerticalSpaceUsedByBox: CGFloat {
        1 - fractionOfVerticalSpaceUsedByTab
    }

    var linearSizeOfBox: CGFloat {
        min(viewSize.width, viewSize.height * fractionOfVerticalSpaceUsedByBox)
    }
    var lidTabRadius: CGFloat {
        fractionOfVerticalSpaceUsedByTab * viewSize.height
    }
    var boxCornerRadius: CGFloat {
        linearSizeOfBox / 50
    }

    var width: CGFloat { linearSizeOfBox }
    var height: CGFloat { linearSizeOfBox + lidTabRadius }
    var hCenter: CGFloat { viewSize.width / 2 }
    var vCenter: CGFloat { linearSizeOfBox / 2 }

    let marginOfBoxEdgeAsFractionOfDieSize: CGFloat = 0.25
    let distanceBetweenDiceAsFractionOfDieSize: CGFloat = 0.15
    var dieSize: CGFloat { return ( linearSizeOfBox / (
      5 +
      4 * distanceBetweenDiceAsFractionOfDieSize +
      2 * marginOfBoxEdgeAsFractionOfDieSize
    ) ) }

    var dieStepSize: CGFloat { (1 + distanceBetweenDiceAsFractionOfDieSize) * dieSize }

    private struct DiePosition: Identifiable {
        let indexInArray: Int
        var face: Face
        var id: Int { indexInArray }
        var column: Int { indexInArray % 5 }
        var row: Int { indexInArray / 5 }
    }

    private var facePositions: [DiePosition] {
        return [Int](0...24).map { index in
            DiePosition(indexInArray: index, face: diceKey.faces[index] )
        }
    }

    var body: some View {
        ZStack {
            // The box
            RoundedRectangle(cornerRadius: boxCornerRadius)
                .size(width: linearSizeOfBox, height: linearSizeOfBox)
                .fill(diceBoxColor)
                .frame(width: linearSizeOfBox, height: linearSizeOfBox)
                .position(x: hCenter, y: vCenter)
            // The lid
            if showLidTab {
                DieLidView(radius: lidTabRadius, color: diceBoxColor)
                .position(x: hCenter, y: vCenter + linearSizeOfBox/2 + lidTabRadius/2)
            }
            // The dice
            ForEach(facePositions) { facePosition in
                DieView(face: facePosition.face, dieSize: dieSize)
                    .position(
                        x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                        y: vCenter + CGFloat(-2 + facePosition.row) * dieStepSize
                    )
            }
        }.frame(width: width, height: height)
    }
}

struct DiceKeyView: View {
    let diceKey: DiceKey
         var showLidTab: Bool = false
    let leaveSpaceForTab: Bool = false
    let diceBoxColor: Color = Color(red: 0x05 / 0xFF, green: 0x03 / 0xFF, blue: 0x50 / 0xFF)

    var aspectRatio: CGFloat { get {
      (showLidTab == true || leaveSpaceForTab == true) ?
        (1 / (1 + fractionOfVerticalSpaceRequiredForTab)) :
        1
    } }

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            GeometryReader { reader in
                DiceKeyViewFixedSize(
                    diceKey: diceKey,
                    viewSize: reader.size,
                    showLidTab: showLidTab,
                    leaveSpaceForTab: leaveSpaceForTab,
                    diceBoxColor: diceBoxColor
                )
            }.aspectRatio(aspectRatio, contentMode: .fit)
            Spacer(minLength: 0)
        }
    }
}

struct DiceKeyView_Previews: PreviewProvider {
//    let diceKey: DiceKey = DiceKey.createFromRandom()

    static var previews: some View {
        DieLidView(radius: 100, color: Color.blue)
            .previewLayout(PreviewLayout.fixed(width: 200, height: 100))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: false)
            .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: true)
            .background(Color.yellow)
    }
}
