//
//  DiceKeyCopyInProgress.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import SwiftUI

struct DiceKeyCopyInProgress: View {
    let diceKey: DiceKey
    var atDieIndex: Int?
    // var foregroundColor: Color?

    var diceBoxColor: Color = Color.diceBox
    var diePenColor: Color = Color.black

    @State var bounds: CGSize = .zero

    var indexestoShow: Set<Int> {
        guard let atDieIndex = self.atDieIndex else { return Set() }
        return Set<Int>(0..<atDieIndex)
    }

    var width: CGFloat { bounds.shorterSide }
    var height: CGFloat { bounds.shorterSide }

    var faceSizeModel: DiceKeySizeModel { DiceKeySizeModel(squareSize: bounds.shorterSide) }
    var faceSize: CGFloat { faceSizeModel.faceSize }
    var faceStepSize: CGFloat { faceSizeModel.stepSize }

    func offset(forFaceIndex faceIndex: Int) -> CGSize {
        let x = CGFloat(-2 + CGFloat(faceIndex % 5)) * faceStepSize
        let y = CGFloat(-2 + CGFloat(Int(faceIndex / 5))) * faceStepSize
        return CGSize(width: x, height: y)
    }

    let handImageWidthAsFractionOfFaceSize: CGFloat = 8.85
    var handImageHeightAsFractionOfFaceSize: CGFloat {
        // Using dimensions from within SVG file
        handImageWidthAsFractionOfFaceSize * CGFloat(187) / CGFloat(219)
    }
    var handImageWidth: CGFloat {
        faceSize * handImageWidthAsFractionOfFaceSize
    }
    var handImageHeight: CGFloat {
        faceSize * handImageHeightAsFractionOfFaceSize
    }
    var handImageOffsetToCenterOfDie: CGSize {
        CGSize(
            width: 0.3704 * handImageWidth,
            height: 0.2852 * handImageHeight
        )
    }

    var body: some View {
        CalculateBounds(bounds: $bounds) { ZStack(alignment: .center) {
            DiceKeyView(diceKey: diceKey, diceBoxColor: diceBoxColor, diePenColor: diePenColor, showDiceAtindexes: indexestoShow)
            if let atDieIndex = self.atDieIndex, atDieIndex < 25 && atDieIndex >= 0 {
                // Highlight-colored box
                RoundedRectangle(cornerRadius: faceSize / 8)
                    .size(width: faceSize * 1.1, height: faceSize * 1.1)
                    .fill(Color.highlighter)
                    .offset(self.offset(forFaceIndex: atDieIndex))
                    .frame(width: faceSize * 1.1, height: faceSize * 1.1)
                // Hand image
                Image("Hand with Sticker")
                    .resizable()
                    .frame(width: handImageWidth, height: handImageHeight)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .offset(handImageOffsetToCenterOfDie)
                    .offset(self.offset(forFaceIndex: atDieIndex))
                    //.mask(foregroundColor)
                // Face being placed
                if let diceKey = self.diceKey {
                    DieView(face: diceKey.faces[atDieIndex], dieSize: faceSize, penColor: diePenColor, faceColor: Color.clear)
                        .offset(self.offset(forFaceIndex: atDieIndex))
                }
            }
        }}.aspectRatio(contentMode: .fit)
    }
}

struct DiceKeyCopyInProgress_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyCopyInProgress(diceKey: DiceKey.createFromRandom(), atDieIndex: 12)
    }
}
