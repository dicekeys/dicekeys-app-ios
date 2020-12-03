//
//  DieFaceView.swift
//
//
//  Created by Stuart Schechter on 2020/11/18.
//

import SwiftUI

struct UndoverlineView: View {
    let face: Face
    let faceSize: CGFloat
    let isOverline: Bool
    let numberOfDots: CGFloat = 11
    var penColor: Color = Color.black
    var holeColor: Color = Color.white

    var width: CGFloat { faceSize * FaceDimensionsFractional.undoverlineLength }
    var height: CGFloat { faceSize * FaceDimensionsFractional.undoverlineThickness }

    var code: Int {
        Int(isOverline ? face.overlineCode11Bits : face.underlineCode11Bits)
    }

    var dotTop: CGFloat { faceSize * FaceDimensionsFractional.undoverlineMarginAlongLength }
    var marginAtStartAndEnd: CGFloat { faceSize * FaceDimensionsFractional.undoverlineMarginAtLineStartAndEnd }
    var dotStep: CGFloat { (width - 2 * marginAtStartAndEnd) / numberOfDots }
    var dotWidth: CGFloat { faceSize *
        // Add buffer of 0.1% of the die width to ensure that
        // white box edges touch
        (FaceDimensionsFractional.undoverlineDotWidth + 0.001) }
    var dotHeight: CGFloat { faceSize * FaceDimensionsFractional.undoverlineDotHeight }

    private struct BitPositionSet: Identifiable {
        let bitPositionLeftToRight: Int
        var id: Int { bitPositionLeftToRight }
    }
    private var bitPositionsSet: [BitPositionSet] {
        let code = self.code
        return (0...10).filter { bitPositionLeftToRight in
            (code & (1 << (10 - bitPositionLeftToRight))) != 0
        }.map { bitPositionLeftToRight in
            BitPositionSet(bitPositionLeftToRight: bitPositionLeftToRight )
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .size(width: width, height: height)
                .fill(penColor)
            ForEach(bitPositionsSet) { bitPositionSet in
                Rectangle()
                    .size(width: dotWidth, height: dotHeight)
                    .fill(holeColor)
                    .offset(
                        x: marginAtStartAndEnd + CGFloat(bitPositionSet.bitPositionLeftToRight) * dotStep,
                        y: dotTop)
            }
        }.frame(width: width, height: height)
    }
}

struct DieFaceUprightView: View {
    let face: Face
    let dieSize: CGFloat
    let linearFractionOfFaceRenderedToDieSize: CGFloat

    var penColor: Color = Color.black
    var faceColor: Color = Color.white
    var faceBorderColor: Color?

    var sizeOfRenderedFace: CGFloat { dieSize * linearFractionOfFaceRenderedToDieSize }

    var left: CGFloat { (dieSize - sizeOfRenderedFace) / 2 }
    var top: CGFloat { (dieSize - sizeOfRenderedFace) / 2 }

    var hCenter: CGFloat { dieSize / 2 }
    var vCenter: CGFloat { dieSize / 2 }

    var textBaseline: CGFloat { top + FaceDimensionsFractional.textBaselineY * sizeOfRenderedFace }
    var letterLeft: CGFloat { left + (1 - FaceDimensionsFractional.textRegionWidth) * sizeOfRenderedFace / 2 }
    var digitLeft: CGFloat { left + (1 + FaceDimensionsFractional.spaceBetweenLetterAndDigit) * sizeOfRenderedFace / 2 }
    var underlineVCenter: CGFloat { top + ( FaceDimensionsFractional.underlineTop + FaceDimensionsFractional.undoverlineThickness / 2) * sizeOfRenderedFace }
    var overlineVCenter: CGFloat { top + ( FaceDimensionsFractional.overlineTop + FaceDimensionsFractional.undoverlineThickness / 2) * sizeOfRenderedFace }
    var overlineTop: CGFloat { top + FaceDimensionsFractional.overlineTop * sizeOfRenderedFace }
    var fontSize: CGFloat {
        FaceDimensionsFractional.fontSize * sizeOfRenderedFace
    }
        var font: Font {
        Font.custom("Inconsolata", size: fontSize)
    }
    var uiFont: UIFont {
        UIFont(name: "Inconsolata-Bold", size: fontSize)!
    }
    var halfTextRegionWidth: CGFloat {
        FaceDimensionsFractional.textRegionWidth * sizeOfRenderedFace / 2
    }
    var textCenterY: CGFloat {
        (
            dieSize
            // Move down to remove region above capital letter
            + (uiFont.capHeight - uiFont.ascender)
            // Move up to remove region below capital letter
            - uiFont.descender
        ) / 2 // take center
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: dieSize / 8)
                .size(width: dieSize, height: dieSize)
                .fill(faceColor)
            if let faceBorderColor = self.faceBorderColor {
                RoundedRectangle(cornerRadius: dieSize / 8)
                    .size(width: dieSize, height: dieSize)
                    .stroke(faceBorderColor)
            }
            Text(face.letter.rawValue)
                .font(.custom("Inconsolata", size: fontSize))
                .fontWeight(.bold)
                .position(x: (dieSize - halfTextRegionWidth) / 2, y: textCenterY)
                .foregroundColor(penColor)
            Text(face.digit.rawValue)
                .font(.custom("Inconsolata", size: fontSize))
                .fontWeight(.bold)
                .position(x: (dieSize + halfTextRegionWidth) / 2, y: textCenterY)
                .foregroundColor(penColor)
            UndoverlineView(face: face, faceSize: sizeOfRenderedFace, isOverline: false, penColor: penColor)
                .position(x: hCenter, y: underlineVCenter)
            UndoverlineView(face: face, faceSize: sizeOfRenderedFace, isOverline: true, penColor: penColor)
                .position(x: hCenter, y: overlineVCenter)
        }
        .frame(width: dieSize, height: dieSize)
    }
}

struct DieFaceView: View {
    let face: Face
    let dieSize: CGFloat
    var linearFractionOfFaceRenderedToDieSize: CGFloat = CGFloat(1)
    var penColor: Color = Color.black
    var faceColor: Color = Color.white
    var faceBorderColor: Color?

    var body: some View {
        DieFaceUprightView(
            face: face,
            dieSize: dieSize,
            linearFractionOfFaceRenderedToDieSize: linearFractionOfFaceRenderedToDieSize,
            penColor: penColor,
            faceColor: faceColor,
            faceBorderColor: faceBorderColor
        ).rotationEffect(Angle(degrees: face.orientationAsLowercaseLetterTrbl.asClockwiseDegrees), anchor: .center)
    }
}

struct DiceKeyFaceArray: View {
    let diceKey: DiceKey
    let marginBetweenDiceFractional: CGFloat = 0.2

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                ForEach(0..<25) { index in
                    DieFaceView(face: diceKey.faces[index], dieSize: geometry.size.width/CGFloat(25),
                        linearFractionOfFaceRenderedToDieSize: 1-marginBetweenDiceFractional/2)
                }
            }
        }
    }
}

struct DieView: View {
    let face: Face
    let dieSize: CGFloat
    let linearFractionOfFaceRenderedToDieSize: CGFloat = CGFloat(5)/8
    var penColor: Color = Color.black
    var faceColor: Color = Color.white
    var faceBorderColor: Color?

    var body: some View {
        DieFaceView(face: face, dieSize: dieSize, linearFractionOfFaceRenderedToDieSize: linearFractionOfFaceRenderedToDieSize, penColor: penColor, faceColor: faceColor, faceBorderColor: faceBorderColor)
    }
}

struct DieFaceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UndoverlineView(face: Face(letter: FaceLetter.A, digit: FaceDigit._3, orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Top), faceSize: 400, isOverline: false)
                .previewLayout(PreviewLayout.fixed(width: 500, height: 100))
        }

        DieFaceView(
            face: Face(letter: FaceLetter.L, digit: FaceDigit._3, orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Right),
            dieSize: 500
        )
        .previewLayout(PreviewLayout.fixed(width: 500, height: 500))

        DiceKeyFaceArray(diceKey: DiceKey.createFromRandom())
        //    .previewLayout(PreviewLayout.fixed(width: 500, height: 100))

        DieView(
            face: Face(letter: FaceLetter.L, digit: FaceDigit._3, orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Right),
            dieSize: 500
        )
        .previewLayout(PreviewLayout.fixed(width: 500, height: 500))
    }
}
