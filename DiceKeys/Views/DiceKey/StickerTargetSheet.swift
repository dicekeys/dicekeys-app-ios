//
//  StickerTargetSheet.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/02.
//

import SwiftUI

struct StickerTargetSheetSpecification {
    static let longSideOverShortSide = CGFloat(155.0/130.0)
    static let shortSideOverLongSide = 1/longSideOverShortSide
    static let lettersPerStickySheet = 5
}

struct StickerTargetSheetFixedSize: View {
    let bounds: CGSize

    let diceKey: DiceKey?
    let showLettersBeforeIndex: Int
    let highlightAtIndex: Int?

    enum Orientation {
        case landscape
        case portrait
    }
    var orientation: Orientation?

    var computedOrientation: Orientation {
        orientation ?? (
            bounds.height >= bounds.width ? .portrait : .landscape
        )
    }

    var width: CGFloat {
        min(
            bounds.width,
            bounds.height * ( computedOrientation == .portrait ? StickerTargetSheetSpecification.shortSideOverLongSide : StickerTargetSheetSpecification.longSideOverShortSide
            )
        )
    }
    var height: CGFloat {
        min(
            bounds.height,
            bounds.width * ( computedOrientation == .landscape ? StickerTargetSheetSpecification.shortSideOverLongSide : StickerTargetSheetSpecification.longSideOverShortSide
            )
        )
    }
    var shorterSideSize: CGFloat {
        min(width, height)
    }

    var faceSizeModel: DiceKeySizeModel { DiceKeySizeModel(squareSize: width) }
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
            width: 0.3695 * handImageWidth,
            height: 0.2845 * handImageHeight
        )
    }
    var letterRange: Range<Int> {
        (0..<showLettersBeforeIndex)
    }

    var body: some View {
        ZStack(alignment: .center) {
            // The sheet
            Rectangle()
                .size(width: width, height: height)
                .fill(Color.white)
                .border(Color.black)
                .frame(width: width, height: height)
            // The dice
            ForEach(0..<25) { faceIndex in
                if faceIndex < showLettersBeforeIndex && diceKey != nil {
                    DieView(face: diceKey!.faces[faceIndex], dieSize: faceSize, faceBorderColor: Color.gray)
                        .offset(self.offset(forFaceIndex: faceIndex))
                } else {
                    Image("Sticker Target")
                    .resizable()
                    .frame(width: faceSize, height: faceSize, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .offset(self.offset(forFaceIndex: faceIndex))
                }
            }
            if let highlightAtIndex = self.highlightAtIndex {
                RoundedRectangle(cornerRadius: faceSize / 8)
                    .size(width: faceSize * 1.2, height: faceSize * 1.2)
                    .fill(Color.highlighter)
                    .offset(self.offset(forFaceIndex: highlightAtIndex))
                    .frame(width: faceSize * 1.2, height: faceSize * 1.2)
                Image("Hand with Sticker")
                    .resizable()
                    .frame(width: handImageWidth, height: handImageHeight)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: width, height: height)
                    .offset(handImageOffsetToCenterOfDie)
                    .offset(self.offset(forFaceIndex: highlightAtIndex))
                if let diceKey = self.diceKey {
                    DieView(face: diceKey.faces[highlightAtIndex], dieSize: faceSize, faceColor: Color.clear)
//                        .rotationEffect(Angle(degrees: -12.5))
                        .offset(self.offset(forFaceIndex: highlightAtIndex))
//                        .offset(x: 0.1 * faceSize, y: 0.185 * faceSize)
                }
            }
        }.frame(width: width, height: height)
    }
}

struct StickerTargetSheet: View {
    var diceKey: DiceKey?
    var showLettersBeforeIndex: Int = 0
    var highlightAtIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            StickerTargetSheetFixedSize(bounds: geometry.size, diceKey: diceKey, showLettersBeforeIndex: showLettersBeforeIndex, highlightAtIndex: highlightAtIndex)
        }
    }
}

struct StickerTargetSheet_Previews: PreviewProvider {
    static var previews: some View {
        StickerTargetSheet(
            diceKey: DiceKey.createFromRandom(),
            showLettersBeforeIndex: 13,
            highlightAtIndex: 13
        ).previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
}
