//
//  DiceKeyView.swift
//  
//
//  Created by Stuart Schechter on 2020/11/18.
//

import SwiftUI

struct DiceKeySizeModel {
    let squareSize: CGFloat

    let marginOfBoxEdgeAsFractionOfDieSize: CGFloat = 0.25
    let distanceBetweenFacesAsFractionOfFaceSize: CGFloat = 0.15
    var faceSize: CGFloat { return ( squareSize / (
      5 +
      4 * distanceBetweenFacesAsFractionOfFaceSize +
      2 * marginOfBoxEdgeAsFractionOfDieSize
    ) ) }

    var stepSize: CGFloat { (1 + distanceBetweenFacesAsFractionOfFaceSize) * faceSize }
}

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

struct DiceKeyView: View {
    let diceKey: DiceKey
    var showLidTab: Bool = false
    var leaveSpaceForTab: Bool = false
    var diceBoxColor: Color = Color.diceBox
    var diceBoxDieSlotColor: Color = Color.diceBoxDieSlot
    var diePenColor: Color = Color.black
    var highlightIndexes: Set<Int> = Set()
    var showDiceAtindexes: Set<Int> = Set(0..<25)

    @State private var viewSize: CGSize = CGSize.zero

    var aspectRatio: CGFloat { get {
      (showLidTab == true || leaveSpaceForTab == true) ?
        (1 / (1 + fractionOfVerticalSpaceRequiredForTab)) :
        1
    } }

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

    private var sizeModel: DiceKeySizeModel {
        DiceKeySizeModel(squareSize: linearSizeOfBox)
    }

    var faceSize: CGFloat { sizeModel.faceSize }
    var dieStepSize: CGFloat { sizeModel.stepSize }

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
        CalculateBounds(bounds: self.$viewSize) {
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
                if showDiceAtindexes.contains(facePosition.id) {
                    DieView(face: facePosition.face, dieSize: faceSize, penColor: diePenColor, faceColor: highlightIndexes.contains(facePosition.indexInArray) ? Color.highlighter : Color.white )
                        .position(
                            x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                            y: vCenter + CGFloat(-2 + facePosition.row) * dieStepSize
                        )
                } else {
                    RoundedRectangle(cornerRadius: faceSize / 8)
                        .size(width: faceSize, height: faceSize)
                        .fill(diceBoxDieSlotColor)
                        .frame(width: faceSize, height: faceSize)
                        .position(
                            x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                            y: vCenter + CGFloat(-2 + facePosition.row) * dieStepSize
                        )
                }
            }
        }}.aspectRatio(aspectRatio, contentMode: .fit)
    }
}

struct DiceKeyView_Previews: PreviewProvider {
//    let diceKey: DiceKey = DiceKey.createFromRandom()

    static var previews: some View {
        DieLidView(radius: 100, color: Color.blue)
            .previewLayout(PreviewLayout.fixed(width: 200, height: 100))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: false)
            .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showDiceAtindexes: Set<Int>(0..<12))
            .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: true)
            .background(Color.yellow)
    }
}
