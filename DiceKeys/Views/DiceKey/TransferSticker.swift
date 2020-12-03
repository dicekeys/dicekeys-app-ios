//
//  TransferSticker.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/02.
//

import SwiftUI

struct TransferStickerFixedWidth: View {
    let bounds: CGSize
    let diceKey: DiceKey
    let faceIndex: Int

    var face: Face {
        diceKey.faces[faceIndex]
    }

    let hMarginFraction: CGFloat = 0.033333
    var fractionalWidthOfPortraitSheet: CGFloat {
        ( CGFloat(1) - 3 * hMarginFraction ) / 2
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

    var stickerSheetColumn: CGFloat {
        CGFloat(faceLetterIndexes[face.letter]! % 5)
    }
    var stickerSheetFirstLetterIndex: Int {
        Int((faceLetterIndexes[face.letter]! / 5) * 5)
    }
    var stickerSheetFirstLetter: FaceLetter {
        FaceLetters[ stickerSheetFirstLetterIndex ]
    }
    var stickerSheetLastLetter: FaceLetter {
        FaceLetters[ stickerSheetFirstLetterIndex + 4 ]
    }
    var stickerSheetRow: CGFloat {
        CGFloat(faceDigitIndexes[face.digit]!)
    }

    var keyColumn: Int {
        Int(faceIndex % 5)
    }
    var keyRow: Int {
        Int(faceIndex / 5)
    }
    var faceIdentifier: String {
        face.letter.rawValue + face.digit.rawValue
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
    var topFacing: String {
        switch face.orientationAsLowercaseLetterTrbl {
        case .Top: return "upright"
        case .Right: return "right"
        case .Bottom: return "down"
        case .Left: return "left"
        }
    }

    var lineStart: CGPoint {
        return CGPoint(
        x:
            // Start at left side of left sheet
            (hMarginFraction * totalWidth) +
            // Move to center of left sheet
            (portraitSheetSize.width / 2) +
            // Move the the center of the face
            ( (stickerSheetColumn - 2) * faceSizeModel.stepSize ) +
            // Move closer to the right edge of the face
            faceSizeModel.faceSize * 0.4,
        y:
            // Move to center height
            (portraitSheetSize.height / 2) +
            // Move to the center of the die
            ( stickerSheetRow - 2.5) * faceSizeModel.stepSize
        )
    }

    var lineEnd: CGPoint {
        return CGPoint(
        x:
            // Start at right side of right sheet
            ((CGFloat(1) - hMarginFraction) * totalWidth) -
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
        VStack {
            ZStack(alignment: .center) {
                HStack(alignment: .center) {
                    Spacer()
                    StickerSheetFixedSize(bounds: portraitSheetSize, showLetter: face.letter, highlightFaceWithDigit: face.digit)
                    Spacer()
                    StickerTargetSheetFixedSize(bounds: portraitSheetSize, diceKey: diceKey, showLettersBeforeIndex: faceIndex, highlightAtIndex: faceIndex)
                    Spacer()
                }
                Path { path in
                    path.move(to: lineStart)
                    path.addLine(to: lineEnd)
                }.stroke(Color.blue, lineWidth: 2.0)
                .frame(width: totalWidth, height: totalHeight)
            }.frame(width: totalWidth, height: totalHeight)
            .padding(.vertical, 3)
            .clipped()
            // Instruction
            HStack {
                Spacer()
                VStack(alignment: .leading) {
                    Text("Remove the \(faceIdentifier) sticker from the sheet with letters \(stickerSheetFirstLetter.rawValue) through \(stickerSheetLastLetter.rawValue).").font(.title3)
                    if face.orientationAsLowercaseLetterTrbl != .Top {
                        Text("Rotate it so the top faces to the \(topFacing).").font(.title3).padding(.top, 3)
                    }
                    Text("Place it squarely covering the target rectangle\( faceIndex == 0 ? " at the top left of the target sheet" : "")."
                    ).font(.title3).padding(.top, 3)
//                    Text("The rectangle at the \(locationDescriptor)."
//                    ).font(.body).padding(.top, 3)
                }
                Spacer()
            }
            // Text("x: \(startingX) y: \(startingY)")
        }
    }
}

struct TransferSticker: View {
    let diceKey: DiceKey
    let faceIndex: Int

    var body: some View {
        GeometryReader { geometry in
            TransferStickerFixedWidth(bounds: geometry.size, diceKey: diceKey, faceIndex: faceIndex)
        }.aspectRatio(contentMode: .fit)
    }
}

let diceKey = DiceKey.createFromRandom()
struct TransferSticker_Previews: PreviewProvider {
    static var previews: some View {
        TransferSticker(diceKey: diceKey, faceIndex: 0)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        TransferSticker(diceKey: diceKey, faceIndex: 13)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
}
