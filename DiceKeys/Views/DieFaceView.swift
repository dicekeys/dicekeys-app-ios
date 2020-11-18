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
        return [Int](0...10).filter { bitPositionLeftToRight in
            (code & (1 << (10 - bitPositionLeftToRight))) != 0
        }.map { bitPositionLeftToRight in
            BitPositionSet(bitPositionLeftToRight: bitPositionLeftToRight )
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .size(width: width, height: height)
                .fill(Color.black)
            ForEach(bitPositionsSet) { bitPositionSet in
                Rectangle()
                    .size(width: dotWidth, height: dotHeight)
                    .fill(Color.white)
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
    let dieColor: Color = Color.white

    let linearFractionOfFaceRenderedToDieSize: CGFloat = 5/8
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
    var halfTextRegionWidth: CGFloat {
        FaceDimensionsFractional.textRegionWidth * sizeOfRenderedFace / 2
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: dieSize / 8)
                .size(width: dieSize, height: dieSize)
                .fill(dieColor)
            Text(face.letter.rawValue)
                .font(.custom("Inconsolata", size: fontSize))
                .fontWeight(.bold)
                .position(x: (dieSize - halfTextRegionWidth) / 2, y: dieSize/2)
                .foregroundColor(.black)
            Text(face.digit.rawValue)
                .font(.custom("Inconsolata", size: fontSize))
                .fontWeight(.bold)
                .position(x: (dieSize + halfTextRegionWidth) / 2, y: dieSize/2)                .foregroundColor(.black)
            UndoverlineView(face: face, faceSize: sizeOfRenderedFace, isOverline: false)
                .position(x: hCenter, y: underlineVCenter)
            UndoverlineView(face: face, faceSize: sizeOfRenderedFace, isOverline: true)
                .position(x: hCenter, y: overlineVCenter)
        }
        .frame(width: dieSize, height: dieSize)
    }
}

struct DieFaceView: View {
    let face: Face
    let dieSize: CGFloat

    var body: some View {
        DieFaceUprightView(face: face, dieSize: dieSize)
            .rotationEffect(Angle(degrees: face.orientationAsLowercaseLetterTrbl.asClockwiseDegrees),
                            anchor: .center)
    }
}

struct DieFaceView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UndoverlineView(face: Face(letter: FaceLetter.A, digit: FaceDigit._3, orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Top),
                             faceSize: 300, isOverline: false)
        }

        DieFaceView(
            face: Face(letter: FaceLetter.A, digit: FaceDigit._3, orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Right),
            dieSize: 300
        )
    }
}
