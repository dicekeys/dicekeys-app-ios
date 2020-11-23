//
//  FaceRead.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation
import SwiftUI

struct Point: Decodable {
    let x: CGFloat
    let y: CGFloat

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct Line: Decodable {
    let start: Point
    let end: Point

    var length: CGFloat {
        CGFloat( sqrt( pow(end.x - start.x, 2) + pow(end.y - start.y, 2) ) )
    }
    var angle: Angle {
        Angle(radians: atan2(Double(end.y - start.y), Double(end.x - start.x)) )
    }
}

struct Undoverline: Decodable {
    let line: Line
    let code: UInt8
}

func decodeUnderlineCode(_ code: UInt8?) -> FaceWithUnderlineAndOverlineCode? {
    if let c = code {
        return underlineCodeToFaceWithUnderlineAndOverlineCode[Int(c)]
    }
    return nil
}
func decodeUnderline(_ underline: Undoverline?) -> FaceWithUnderlineAndOverlineCode? {
    return decodeUnderlineCode(underline?.code)
}

func averageAngles (_ angles: Angle...) -> Angle {
    guard angles.count > 0 else {
        return Angle(radians: 0)
    }
    let sumSin = angles.reduce( Double(0), { sum, angle in
        sum + sin(angle.radians)
    })
    let sumCos = angles.reduce( Double(0), { sum, angle in
        sum + cos(angle.radians)
    })
    if sumSin == 0 && sumCos == 0 {
        // Corner case.  Two possible averages, pick one
        return Angle(radians: (angles[0].radians) + Double.pi)
    }
    return Angle(radians: atan2(sumSin, sumCos))
}

func decodeOverlineCode(_ code: UInt8?) -> FaceWithUnderlineAndOverlineCode? {
    if let c = code {
        return overlineCodeToFaceWithUnderlineAndOverlineCode[Int(c)]
    }
    return nil
}
func decodeOverline(_ overline: Undoverline?) -> FaceWithUnderlineAndOverlineCode? {
    return decodeOverlineCode(overline?.code)
}

func majorityOf3<T: Equatable>(_ a: T?, _ b: T?, _ c: T?) -> T? {
    return (a == b || a == c) ? a : (b == c) ? b : nil
}

class FaceRead: Decodable {
    let underline: Undoverline?
    let overline: Undoverline?
    let orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl?
    let ocrLetterCharsFromMostToLeastLikely: String
    let ocrDigitCharsFromMostToLeastLikely: String
    let center: Point

    private var decodedUnderline: FaceWithUnderlineAndOverlineCode? {
        decodeUnderline(underline)
    }

    private var decodedOverline: FaceWithUnderlineAndOverlineCode? {
        decodeOverline(overline)
    }

    var letter: FaceLetter? { get {
        return majorityOf3(
            FaceLetter(rawValue: String(ocrLetterCharsFromMostToLeastLikely.prefix(1))),
            decodedUnderline?.letter,
            decodedOverline?.letter
        )
    }}

    var digit: FaceDigit? { get {
        return majorityOf3(
            FaceDigit(rawValue: String(ocrDigitCharsFromMostToLeastLikely.prefix(1))),
            decodedUnderline?.digit,
            decodedOverline?.digit
        )
    }}

    var angle: Angle? {
        let undoverline1 = underline ?? overline
        let undoverline2 = underline == nil ? nil : overline
        if undoverline2 != nil {
            return averageAngles(undoverline1!.line.angle, undoverline2!.line.angle)
        } else if undoverline1 != nil {
            return undoverline1!.line.angle
        } else {
            return nil
        }
    }

    var length: CGFloat? {
        let undoverline1 = underline ?? overline
        let undoverline2 = underline == nil ? nil : overline
        if undoverline2 != nil {
            return (undoverline1!.line.length + undoverline2!.line.length) / 2
        } else if undoverline1 != nil {
            return undoverline1!.line.length
        } else {
            return nil
        }
    }

    func toFace() -> Face? {
        if let letter = self.letter, let digit = self.digit {
            return Face(
                letter: letter,
                digit: digit,
                orientationAsLowercaseLetterTrbl: orientationAsLowercaseLetterTrbl ?? FaceOrientationLetterTrbl.Top)
        }
        return nil
    }
    static func fromJson(_ json: Data) -> [FaceRead]? {
        return try? JSONDecoder().decode([FaceRead].self, from: json)
    }

    static func fromJson(_ json: String) -> [FaceRead]? {
        return fromJson(json.data(using: .utf8)!)
    }

    enum FaceReadErrorLocationLine {
        case Underline, Overline
    }
    enum FaceReadErrorLocationCharacter {
        case Letter, Digit
    }

    enum FaceReadError {
        case UndoverlineBitMismatch(
            FaceReadErrorLocationLine // , hammingDistance: Int
        )
        case UndoverlineMissing(
            FaceReadErrorLocationLine
        )
        case UndoverlineCharacterWasOcrsSecondChoice(
            FaceReadErrorLocationCharacter
        )
        case UndoverlineCharacterDidNotMatchOcrCharacter(
            FaceReadErrorLocationCharacter
        )
        case NoUndoverlineOrOverlineWithWhichToLocateFace
        case NoMajorityAgreement
    }

    var errors: [FaceReadError] {
        var errorList: [FaceReadError] = []

        let decodedUnderline = self.decodedUnderline
        let decodedOverline = self.decodedOverline
        let underlineLetter = decodedUnderline?.letter.rawValue
        let underlineDigit = decodedUnderline?.digit.rawValue
        let overlineLetter = decodedOverline?.letter.rawValue
        let overlineDigit = decodedOverline?.digit.rawValue
        let ocrLetter = String(ocrLetterCharsFromMostToLeastLikely.prefix(1))
        let ocrLetter2 = String(ocrLetterCharsFromMostToLeastLikely.prefix(2).suffix(1))
        let ocrDigit = String(ocrDigitCharsFromMostToLeastLikely.prefix(1))
        let ocrDigit2 = String(ocrDigitCharsFromMostToLeastLikely.prefix(2).suffix(1))

        if  underlineLetter != nil &&
            underlineDigit != nil &&
            underlineLetter == overlineLetter &&
            underlineDigit == overlineDigit {
            // The underline and overline map to the same face

            // Check for OCR errors for the letter read
            if underlineLetter != ocrLetter {
                errorList.append(underlineLetter == ocrLetter2 ?
                                    .UndoverlineCharacterWasOcrsSecondChoice(.Letter) :
                                    .UndoverlineCharacterDidNotMatchOcrCharacter(.Letter)
                )
            }
            if underlineDigit != ocrDigit {
                errorList.append(underlineDigit == ocrDigit2 ?
                                    .UndoverlineCharacterWasOcrsSecondChoice(.Digit) :
                                    .UndoverlineCharacterDidNotMatchOcrCharacter(.Digit)
                )
            }
        } else if underlineLetter == ocrLetter && underlineDigit == ocrDigit {
            // The underline and the OCR-read letter & digit match, so the error is in the overline
            errorList.append(
                overline == nil ? .UndoverlineMissing(.Overline) : .UndoverlineBitMismatch(.Overline) // hammingDistance( underline.faceWithUndoverlineCodes && underline.faceWithUndoverlineCodes.overlineCode || 0,                        overline.code
            )
        } else if overlineLetter == ocrLetter && overlineDigit == ocrDigit {
            // The overline and the OCR-read letter & digit match, so the error is in the underline
            errorList.append(
                underline == nil ? .UndoverlineMissing(.Underline) : .UndoverlineBitMismatch(.Underline)
            )
        } else if underline == nil && overline == nil {
            // If we've made it this far down the if/then/else block, it's possible
            // that neither and underline or overline was read
            errorList.append(.NoUndoverlineOrOverlineWithWhichToLocateFace)
        } else {
            errorList.append(.NoMajorityAgreement)
        }
        return errorList
    }
}
