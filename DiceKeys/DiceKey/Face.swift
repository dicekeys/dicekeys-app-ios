//
//  Face.swift
//
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

extension FaceOrientationLetterTrbl {
    func rotate90() -> FaceOrientationLetterTrbl {
        switch self {
            case FaceOrientationLetterTrbl.Top: return FaceOrientationLetterTrbl.Right
            case FaceOrientationLetterTrbl.Right: return FaceOrientationLetterTrbl.Bottom
            case FaceOrientationLetterTrbl.Bottom: return FaceOrientationLetterTrbl.Left
            case FaceOrientationLetterTrbl.Left: return FaceOrientationLetterTrbl.Top
        }
    }
    
    var asClockwiseRadians: Double {
        switch self {
            case FaceOrientationLetterTrbl.Top: return 0
            case FaceOrientationLetterTrbl.Right: return Double.pi / 2
            case FaceOrientationLetterTrbl.Bottom: return Double.pi
            case FaceOrientationLetterTrbl.Left: return Double.pi * 3 / 2
        }
    }

    var asClockwiseDegrees: Double {
        switch self {
            case FaceOrientationLetterTrbl.Top: return 0
            case FaceOrientationLetterTrbl.Right: return 90
            case FaceOrientationLetterTrbl.Bottom: return 180
            case FaceOrientationLetterTrbl.Left: return 270
        }
    }

}

struct Face {
    let letter: FaceLetter
    let digit: FaceDigit
    let orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl
    
    func rotate90() -> Face {
            return Face(letter: letter, digit: digit, orientationAsLowercaseLetterTrbl: self.orientationAsLowercaseLetterTrbl.rotate90()
        )
    }
    
    private var faceWithUnderlineAndOverlineCode: FaceWithUnderlineAndOverlineCode {
        letterIndexTimesSixPlusDigitIndexFaceWithUndoverlineCodes[
            Int(faceLetterIndexes[letter]!) * 6 + Int(faceDigitIndexes[digit]!)
        ]
    }
    
    var underlineCode8Bits: UInt8 { faceWithUnderlineAndOverlineCode.underlineCode }
    var overlineCode8Bits: UInt8 { faceWithUnderlineAndOverlineCode.overlineCode }

    var underlineCode11Bits: UInt16 {
        // always set the high order bit (bit 11: 1 << 10) to 1 and low order bit to 0
        // to signal order
        (1 << 10) |
        // set the next high-order bit only on overlines
        0 |
        // shift the face code 1 to the left to leave the 0th bit empty
        ( UInt16(underlineCode8Bits) << 1 )
    }
    
    var overlineCode11Bits: UInt16 {
        // always set the high order bit (bit 11: 1 << 10) to 1 and low order bit to 0
        // to signal order
        (1 << 10) |
        // set the next high-order bit on overlines
        (1 << 9) |
        // shift the face code 1 to the left to leave the 0th bit empty
        ( UInt16(overlineCode8Bits) << 1 )
    }
}


