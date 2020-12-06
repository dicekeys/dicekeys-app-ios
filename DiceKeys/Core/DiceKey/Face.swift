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

protocol FaceIdentifier {
    var letter: FaceLetter { get }
    var digit: FaceDigit { get }
}

struct FaceIdentity: FaceIdentifier {
    let letter: FaceLetter
    let digit: FaceDigit
}

struct Face: FaceIdentifier {
    let letter: FaceLetter
    let digit: FaceDigit
    let orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl

    var letterAndDigit: String {
        letter.rawValue + digit.rawValue
    }
    
    var humanReadableForm: String {
        letter.rawValue + digit.rawValue + orientationAsLowercaseLetterTrbl.rawValue
    }

    func rotate90() -> Face {
            return Face(letter: letter, digit: digit, orientationAsLowercaseLetterTrbl: self.orientationAsLowercaseLetterTrbl.rotate90()
        )
    }

    func numberOfFieldsDifferent(fromOtherFace other: Face) -> Int {
        var numberOfFields: Int = 0
        if letter != other.letter {
            numberOfFields += 1
        }
        if digit != other.digit {
            numberOfFields += 1
        }
        if orientationAsLowercaseLetterTrbl != other.orientationAsLowercaseLetterTrbl {
            numberOfFields += 1
        }
        return numberOfFields
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

    init(letter: FaceLetter,
         digit: FaceDigit,
         orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl
    ) {
        self.letter = letter
        self.digit = digit
        self.orientationAsLowercaseLetterTrbl = orientationAsLowercaseLetterTrbl
    }

    enum IllegalCharacterError: Error {
        case inLetter(position: Int)
        case inDigit(position: Int)
        case inOrientation(position: Int)
    }

    init(fromHumanReadableForm humanReadableForm: String, offsetErrorIndxesBy: Int = 0) throws {
        guard let letter = FaceLetter(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: 0)])) else {
            throw IllegalCharacterError.inLetter(position: offsetErrorIndxesBy + 0)
        }
        guard let digit = FaceDigit(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: 1)])) else {
            throw IllegalCharacterError.inDigit(position: offsetErrorIndxesBy + 1)
        }
        guard let orientationAsLowercaseLetterTrbl = humanReadableForm.count > 2 ? FaceOrientationLetterTrbl(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: 2)])) :
            FaceOrientationLetterTrbl.Top else {
            throw IllegalCharacterError.inOrientation(position: offsetErrorIndxesBy + 2)
        }
        self.init(
            letter: letter,
            digit: digit,
            orientationAsLowercaseLetterTrbl: orientationAsLowercaseLetterTrbl
        )
    }
}
