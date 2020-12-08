//
//  DiceKeyView.swift
//  
//
//  Created by Stuart Schechter on 2020/11/18.
//

import SwiftUI

struct DiceKeySizeModel {
    let bounds: CGSize
    init (_ bounds2d: CGSize, hasTab: Bool = false) {
        bounds = bounds2d
        self.hasTab = hasTab
    }
    init (_ bounds1d: CGFloat, hasTab: Bool = false) {
        bounds = CGSize(width: bounds1d, height: bounds1d)
        self.hasTab = hasTab
    }

    var hasTab: Bool = false

    let fractionOfVerticalSpaceRequiredForTab: CGFloat = 0.1

    var aspectRatio: CGFloat { get {
      (hasTab) ?
        (1 - fractionOfVerticalSpaceUsedByTab) :
        1
    }}

    var width: CGFloat { min(bounds.width, bounds.height * aspectRatio) }
    var height: CGFloat { min(bounds.height, bounds.width / aspectRatio) }

    var size: CGSize {
        CGSize(width: width, height: height)
    }

    var fractionOfVerticalSpaceUsedByTab: CGFloat {
        hasTab ? fractionOfVerticalSpaceRequiredForTab : 0
    }

    var fractionOfVerticalSpaceUsedByBox: CGFloat {
        1 - fractionOfVerticalSpaceUsedByTab
    }

    var linearSizeOfBox: CGFloat {
        width
    }

    var lidTabRadius: CGFloat {
        height * fractionOfVerticalSpaceUsedByTab
    }

    var boxCornerRadius: CGFloat {
        linearSizeOfBox / 50
    }

    var offsetToBoxCenterY: CGFloat {
        -lidTabRadius / 2
    }

    var centerY: CGFloat {
        height / 2
    }
    var boxCenterY: CGFloat {
        centerY + offsetToBoxCenterY
    }
    var centerX: CGFloat {
        width / 2
    }

    let marginOfBoxEdgeAsFractionOfDieSize: CGFloat = 0.25
    let distanceBetweenFacesAsFractionOfFaceSize: CGFloat = 0.15
    var faceSize: CGFloat { return ( linearSizeOfBox / (
      5 +
      4 * distanceBetweenFacesAsFractionOfFaceSize +
      2 * marginOfBoxEdgeAsFractionOfDieSize
    ) ) }

    let faceRadiusAsFractionOfSize: CGFloat = 1/8
    var faceRadius: CGFloat { faceSize * faceRadiusAsFractionOfSize }

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

struct DiceKeyView: View {
    var diceKey: DiceKey?
    var centerFace: Face?
    var showLidTab: Bool = false
    var leaveSpaceForTab: Bool = false
    var diceBoxColor: Color = Color.diceBox
    var diceBoxDieSlotColor: Color = Color.diceBoxDieSlot
    var diePenColor: Color = Color.black
    var faceSurfaceColor: Color = Color.white
    var highlightIndexes: Set<Int> = Set()
    var showDiceAtIndexes: Set<Int>?

    @State private var viewSize: CGSize = CGSize.zero

    var computedDiceKeyToRender: DiceKey {
        if let diceKey = self.diceKey {
            // If the caller specified a diceKey, use that
            return diceKey
        } else if let centerFace = self.centerFace {
            // If the caller specified a center face, create a
            // diceKey with just that face for all dice
            return DiceKey( (0..<25).map { _ in centerFace })
        } else {
            // If no diceKey was specified, we'll render the example diceKey
            return DiceKey.Example
        }
    }

    var computedShowDiceAtIndexes: Set<Int> {
        showDiceAtIndexes ?? (
            // If the caller did not directly specify which indexes to show,
            // show only the center die if the diceKey is specified via centerFace,
            // and how all 25 dice otherwise
            (diceKey == nil && centerFace != nil) ?
                // Just the center die
                Set([12]) :
                // all 25 dice
                Set(0..<25)
        )
    }

    private var sizeModel: DiceKeySizeModel {
        DiceKeySizeModel(viewSize, hasTab: showLidTab || leaveSpaceForTab)
    }

    var hCenter: CGFloat { sizeModel.centerX }
    var vCenterOfView: CGFloat { sizeModel.centerY }
    var vCenterOfBox: CGFloat { sizeModel.boxCenterY }
    var faceSize: CGFloat { sizeModel.faceSize }
    var dieStepSize: CGFloat { sizeModel.stepSize }
    var width: CGFloat { sizeModel.width }
    var height: CGFloat { sizeModel.height }
    var linearSizeOfBox: CGFloat { sizeModel.linearSizeOfBox }

    private struct DiePosition: Identifiable {
        let indexInArray: Int
        var face: Face
        var id: Int { indexInArray }
        var column: Int { indexInArray % 5 }
        var row: Int { indexInArray / 5 }
    }

    private var facePositions: [DiePosition] {
        return [Int](0...24).map { index in
            DiePosition(indexInArray: index, face: computedDiceKeyToRender.faces[index] )
        }
    }

    var body: some View {
        CalculateBounds(bounds: self.$viewSize) {
        ZStack {
            // The box
            RoundedRectangle(cornerRadius: sizeModel.boxCornerRadius)
                .size(width: linearSizeOfBox, height: linearSizeOfBox)
                .fill(diceBoxColor)
                .frame(width: linearSizeOfBox, height: linearSizeOfBox)
                .position(x: hCenter, y: vCenterOfBox)
            // The lid
            if showLidTab {
                DieLidView(radius: sizeModel.lidTabRadius, color: diceBoxColor)
                    .position(x: hCenter, y: vCenterOfBox + sizeModel.linearSizeOfBox/2 + sizeModel.lidTabRadius/2)
            }
            // The dice
            ForEach(facePositions) { facePosition in
                if computedShowDiceAtIndexes.contains(facePosition.id) {
                    DieView(face: facePosition.face, dieSize: faceSize, penColor: diePenColor, faceSurfaceColor: highlightIndexes.contains(facePosition.indexInArray) ? Color.highlighter : faceSurfaceColor )
                        .position(
                            x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                            y: vCenterOfBox + CGFloat(-2 + facePosition.row) * dieStepSize
                        )
                } else {
                    RoundedRectangle(cornerRadius: sizeModel.faceRadius)
                        .size(width: faceSize, height: faceSize)
                        .fill(diceBoxDieSlotColor)
                        .frame(width: faceSize, height: faceSize)
                        .position(
                            x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                            y: vCenterOfBox + CGFloat(-2 + facePosition.row) * dieStepSize
                        )
                }
            }
        }}.aspectRatio(sizeModel.aspectRatio, contentMode: .fit)
    }
}

struct DiceKeyView_Previews: PreviewProvider {
//    let diceKey: DiceKey = DiceKey.createFromRandom()

    static var previews: some View {
        DieLidView(radius: 100, color: Color.blue)
            .previewLayout(PreviewLayout.fixed(width: 200, height: 100))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: false)
            .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showDiceAtIndexes: Set<Int>(0..<12))
            .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: true)
            .background(Color.yellow)
    }
}
