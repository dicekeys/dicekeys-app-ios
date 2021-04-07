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
        bounds.height / 2
    }
    var boxCenterY: CGFloat {
        centerY + offsetToBoxCenterY
    }
    var centerX: CGFloat {
        bounds.width / 2
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
    var partialFaces: [PartialFace]?
    var centerFace: Face?
    var showLidTab: Bool = false
    var hideFaces: Bool = false
    var withShowDiceLabel: Bool = false
    var leaveSpaceForTab: Bool = false
    var diceBoxColor: Color = Color.diceBox
    var diceBoxDieSlotColor: Color = Color.diceBoxDieSlot
    var diceBoxDieSlotHiddenColor: Color = Color.diceBox.opacity(0.8)
    var diePenColor: Color = Color.black
    var faceSurfaceColor: Color = Color.white
    var highlightIndexes: Set<Int> = Set()
    var showDiceAtIndexes: Set<Int>?
    var aspectRatioMatchStickeys: Bool = false
    var onFacePressed: ((_ faceIndex: Int) -> Void)?
    
    @AppStorage(Settings.hideDiceExceptCenterDie) var hideDiceExceptCenterDie: Bool = false

    @State private var viewSize: CGSize = CGSize.zero

    var partialFacesToRender: [PartialFace] {
        if let diceKey = self.diceKey {
            // If the caller specified a diceKey, use that
            return (0..<25).map { index in PartialFace(diceKey.faces[index], index: index) }
        } else if let centerFace = self.centerFace {
            // If the caller specified a center face, create a
            // diceKey with just that face for all dice
            return (0..<25).map { index in PartialFace(centerFace, index: index) }
        } else if let partialFaces = partialFaces {
            return partialFaces
        } else {
            // If no diceKey was specified, we'll render the example diceKey
            let diceKey = DiceKey.Example
            return (0..<25).map { index in PartialFace(diceKey.faces[index], index: index) }
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
        var partialFace: PartialFace
        var id: Int { indexInArray }
        var column: Int { indexInArray % 5 }
        var row: Int { indexInArray / 5 }
    }

    private var facePositions: [DiePosition] {
        let partialFaces = partialFacesToRender
        return [Int](0...24).map { index in
            DiePosition(indexInArray: index, partialFace: partialFaces[index] )
        }
    }

    func toggleHideFaces() {
        if(hideFaces){
            UserDefaults.standard.set(!self.hideDiceExceptCenterDie, forKey: Settings.hideDiceExceptCenterDie)
        }
    }

    var body: some View {
        VStack{
            CalculateBounds(bounds: self.$viewSize) {
                ZStack(alignment: .center) {
                    // The box
                    RoundedRectangle(cornerRadius: sizeModel.boxCornerRadius)
                        .size(width: linearSizeOfBox, height: linearSizeOfBox)
                        .fill(diceBoxColor)
                        .frame(width: linearSizeOfBox, height: linearSizeOfBox)
                        .position(x: hCenter, y: vCenterOfBox)
                    // The lid
                    if showLidTab && (!hideFaces || hideDiceExceptCenterDie) {
                        DieLidView(radius: sizeModel.lidTabRadius, color: diceBoxColor)
                            .position(x: hCenter, y: vCenterOfBox + sizeModel.linearSizeOfBox/2 + sizeModel.lidTabRadius/2)
                    }
                    // The dice
                    ForEach(facePositions) { facePosition in
                        
                        let dieIsCenterDie = (facePosition.indexInArray == 12)
                        if (computedShowDiceAtIndexes.contains(facePosition.id) && (!hideFaces || !hideDiceExceptCenterDie || dieIsCenterDie)) {
                            DieView(partialFace: facePosition.partialFace, dieSize: faceSize, penColor: diePenColor, faceSurfaceColor: highlightIndexes.contains(facePosition.indexInArray) ? Color.highlighter : faceSurfaceColor )
                                .position(
                                    x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                                    y: vCenterOfBox + CGFloat(-2 + facePosition.row) * dieStepSize
                                )
                                .if(onFacePressed != nil) {
                                    $0.onTapGesture {
                                        onFacePressed?(facePosition.indexInArray)
                                    }
                                }
                        }else{
                            RoundedRectangle(cornerRadius: sizeModel.faceRadius)
                                .size(width: faceSize, height: faceSize)
                                .fill(diceBoxDieSlotColor)
                                .frame(width: faceSize, height: faceSize)
                                .position(
                                    x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                                    y: vCenterOfBox + CGFloat(-2 + facePosition.row) * dieStepSize
                                )
                        }

                        
                        if(hideFaces && hideDiceExceptCenterDie) {
                            RoundedRectangle(cornerRadius: sizeModel.faceRadius)
                                .size(width: faceSize, height: faceSize)
                                .fill(dieIsCenterDie ? diceBoxDieSlotHiddenColor.opacity(0.5) : diceBoxDieSlotHiddenColor)
                                .frame(width: faceSize, height: faceSize)
                                .position(
                                    x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                                    y: vCenterOfBox + CGFloat(-2 + facePosition.row) * dieStepSize
                                )
                        }
                    }
                }

            }
            .aspectRatio(aspectRatioMatchStickeys ? 130/155 : sizeModel.aspectRatio, contentMode: .fit)
            .if(hideFaces) {
                $0.onTapGesture {
                    toggleHideFaces()
                }
            }
            
            if(withShowDiceLabel){
                Text("tap to show dice")
                    .font(.footnote)
                    .opacity(hideDiceExceptCenterDie ? 1 : 0)
                    .padding()
            }
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

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showDiceAtIndexes: Set<Int>(0..<12))
            .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: true)
            .background(Color.yellow)
    }
}
