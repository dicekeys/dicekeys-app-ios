//
//  TransferSticker.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/02.
//

import SwiftUI

struct StickerSheetForFace {
    let face: Face

    private var letterIndexOfFirstColumn: Int {
        Int((faceLetterIndexes[face.letter]! / 5) * 5)
    }
    var firstLetter: FaceLetter {
        FaceLetters[ letterIndexOfFirstColumn ]
    }
    var lastLetter: FaceLetter {
        FaceLetters[ letterIndexOfFirstColumn + 4 ]
    }

    var column: CGFloat {
        CGFloat(faceLetterIndexes[face.letter]! % 5)
    }
    var row: CGFloat {
        CGFloat(faceDigitIndexes[face.digit]!)
    }
}

struct TransferStickerInstructions: View {
    let diceKey: DiceKey
    var faceIndex: Int

    var face: Face {
        diceKey.faces[faceIndex]
    }

    var stickerSheet: StickerSheetForFace {
        StickerSheetForFace(face: face)
    }

    var faceIdentifier: String {
        face.letter.rawValue + face.digit.rawValue
    }

    var topFacing: String {
        switch face.orientationAsLowercaseLetterTrbl {
        case .Top: return "upright"
        case .Right: return "right"
        case .Bottom: return "down"
        case .Left: return "left"
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Remove the \(faceIdentifier) sticker from the sheet with letters \(stickerSheet.firstLetter.rawValue) through \(stickerSheet.lastLetter.rawValue).").font(.title)
            if face.orientationAsLowercaseLetterTrbl != .Top {
                Text("Rotate it so the top faces to the \(topFacing).").font(.title).padding(.top, 3)
            }
            Text("Place it squarely covering the target rectangle\( faceIndex == 0 ? " at the top left of the target sheet" : "")."
            ).font(.title).padding(.top, 3)
        }
    }
}

struct TransferSticker: View {
    @State var bounds: CGSize = .zero
    let diceKey: DiceKey
    var faceIndex: Int

    let sideMarginFraction: CGFloat = 0
    let centerMarginFraction: CGFloat = 0.05
    var aspectRatio: CGFloat {
        2 * StickerTargetSheetSpecification.shortSideOverLongSide +
        2 * sideMarginFraction +
        2 * centerMarginFraction
    }
    
    var fractionalWidthOfPortraitSheet: CGFloat {
        ( CGFloat(1) - (2 * sideMarginFraction + centerMarginFraction) ) / 2
    }
    var totalHeight: CGFloat {
        min(
            bounds.height,
            (bounds.width * fractionalWidthOfPortraitSheet) * StickerTargetSheetSpecification.longSideOverShortSide
        )
    }
    var portraitSheetSize: CGSize {
        CGSize(width: totalHeight * StickerTargetSheetSpecification.shortSideOverLongSide, height: totalHeight)
    }
    var totalWidth: CGFloat {
        portraitSheetSize.width / fractionalWidthOfPortraitSheet
    }

    var faceSizeModel: DiceKeySizeModel { DiceKeySizeModel(squareSize: portraitSheetSize.width) }
    var faceSize: CGFloat { faceSizeModel.faceSize }
    var faceStepSize: CGFloat { faceSizeModel.stepSize }

    var face: Face {
        diceKey.faces[faceIndex]
    }

    private var stickerSheet: StickerSheetForFace {
        StickerSheetForFace(face: face)
    }

    var keyColumn: Int {
        Int(faceIndex % 5)
    }
    var keyRow: Int {
        Int(faceIndex / 5)
    }

    let rowOrderNames = [
        "top row", "second row from the top",
        "third row from the top", "fourth row from the top", "bottom row"
    ]
    let columnOrderNames = [
        "left-most column",
        "second column from left",
        "third column from the left",
        "fourth column from the left",
        "right-most column"
    ]
    var locationDescriptor: String {
        faceIndex == 0 ?
           "top left" :
           (rowOrderNames[keyRow] + ", " + columnOrderNames[keyColumn])
    }

    var lineStart: CGPoint {
        return CGPoint(
        x:
            // Start at left side of left sheet
            (sideMarginFraction * totalWidth) +
            // Move to center of left sheet
            (portraitSheetSize.width / 2) +
            // Move the the center of the face
            ( (stickerSheet.column - 2) * faceSizeModel.stepSize ) +
            // Move closer to the right edge of the face
            faceSizeModel.faceSize * 0.4,
        y:
            // Move to center height
            (portraitSheetSize.height / 2) +
            // Move to the center of the die
            ( stickerSheet.row - 2.5) * faceSizeModel.stepSize
        )
    }

    var lineEnd: CGPoint {
        return CGPoint(
        x:
            // Start at right side of right sheet
            ((CGFloat(1) - sideMarginFraction) * totalWidth) -
            // Move to center of left sheet
            (portraitSheetSize.width / 2) +
            // Move the the center of the face
            ( CGFloat(keyColumn) - 2 ) * faceSizeModel.stepSize -
            // Move closer to the left edge of the face
            faceSizeModel.faceSize * 0.4,
        y:
            // Move to center height
            (portraitSheetSize.height / 2) +
            // Move to the center of the die
            ( CGFloat(keyRow) - 2) * faceSizeModel.stepSize
        )
    }

    var body: some View {
        ChildSizeReader(size: $bounds) {
            HStack(alignment: .center, spacing: 0) {
                StickerSheet(showLetter: face.letter, highlightFaceWithDigit: face.digit)//.frame(width: portraitSheetSize.width, height: portraitSheetSize.height)
                Spacer().frame(maxWidth: bounds.width * centerMarginFraction)
                StickerTargetSheet(diceKey: diceKey, showLettersBeforeIndex: faceIndex, highlightAtIndex: faceIndex)//.frame(width: portraitSheetSize.width, height: portraitSheetSize.height)
            }.overlay(
                Path { path in
                    path.move(to: lineStart)
                    path.addLine(to: lineEnd)
                }.stroke(Color.blue, lineWidth: 2.0)
            )
        }.aspectRatio(aspectRatio, contentMode: .fit)
    }
}

let diceKey = DiceKey.createFromRandom()
struct TransferSticker_Previews: PreviewProvider {
    static var previews: some View {
        TransferSticker(diceKey: diceKey, faceIndex: 24)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        TransferSticker(diceKey: diceKey, faceIndex: 0)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        TransferSticker(diceKey: diceKey, faceIndex: 13)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
}
