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

    var letter: FaceLetter? { get {
        return majorityOf3(
            FaceLetter(rawValue: String(ocrLetterCharsFromMostToLeastLikely.prefix(1))),
            decodeUnderline(underline)?.letter,
            decodeOverline(overline)?.letter
        )
    }}

    var digit: FaceDigit? { get {
        return majorityOf3(
            FaceDigit(rawValue: String(ocrDigitCharsFromMostToLeastLikely.prefix(1))),
            decodeUnderline(underline)?.digit,
            decodeOverline(overline)?.digit
        )
    }}

    var angle: Angle? {
        let undoverline1 = underline ?? overline
        let undoverline2 = underline == nil ? nil : overline
        if undoverline2 != nil {
            return (undoverline1!.line.angle + undoverline2!.line.angle) / 2
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
}
