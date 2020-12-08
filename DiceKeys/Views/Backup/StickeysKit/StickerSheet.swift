//
//  StickySheet.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/02.
//

import SwiftUI

private let nativeHeightOverWidth = CGFloat(155.0/130.0)
private let nativeWidthOverHeight = 1/nativeHeightOverWidth
private let lettersPerStickySheet = 5

struct StickerSheet: View {
    var showLetter: FaceLetter = FaceLetter.A
    var highlightFaceWithDigit: FaceDigit?
    let penColorOfHighlightedFace: Color = Color(CGColor(red: 0, green: 0, blue: 0, alpha: 0.2))

    var maxFractionalSpace = CGFloat(0.8)
    @State private var bounds: CGSize = .zero

    var height: CGFloat {
        min(bounds.height,
            nativeHeightOverWidth * bounds.width
        )
    }

    var pageIndex: Int {
        Int(faceLetterIndexes[showLetter]!) / lettersPerStickySheet
    }
    var firstLetterIndex: Int {
        pageIndex * lettersPerStickySheet
    }
    var letterIndexesOnPage: Range<Int> {
        (firstLetterIndex..<(firstLetterIndex + lettersPerStickySheet))
    }

    var width: CGFloat {
        height * nativeWidthOverHeight
    }

    var faceSizeModel: DiceKeySizeModel { DiceKeySizeModel(width) }
    var faceSize: CGFloat { faceSizeModel.faceSize }
    var faceStepSize: CGFloat { faceSizeModel.stepSize }

    var body: some View {
        CalculateBounds(bounds: $bounds) {
        ZStack(alignment: .center) {
            // The sheet
            Rectangle()
                .size(width: width, height: height)
                .fill(Color.white)
                .border(Color.black)
                .frame(width: width, height: height)
            // The dice
            ForEach(0..<5) { letterIndexOnPage in
                ForEach(0..<6) { digitIndex in
                    DieView(
                        face: Face(letter: FaceLetters[firstLetterIndex + letterIndexOnPage], digit: FaceDigits[digitIndex], orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Top),
                        dieSize: faceSize,
                        penColor: (showLetter == FaceLetters[firstLetterIndex + letterIndexOnPage] && highlightFaceWithDigit == FaceDigits[digitIndex]) ? penColorOfHighlightedFace : Color.black,
                        faceSurfaceColor: (showLetter == FaceLetters[firstLetterIndex + letterIndexOnPage] && highlightFaceWithDigit == FaceDigits[digitIndex]) ? Color.highlighter : Color.white,
                        faceBorderColor: Color.gray
                    ).offset(
                        x: CGFloat(-2 + (letterIndexOnPage)) * faceStepSize,
                        y: CGFloat(-2.5 + CGFloat(digitIndex)) * faceStepSize
                    )
                }
            }
        }}.aspectRatio(nativeWidthOverHeight, contentMode: .fit)
    }
}

struct StickerSheet_Previews: PreviewProvider {
    static var previews: some View {
        StickerSheet(showLetter: FaceLetter.Z, highlightFaceWithDigit: FaceDigit._2)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        StickerSheet(showLetter: FaceLetter.S, highlightFaceWithDigit: FaceDigit._5)
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
}
