//
//  FaceRead.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

struct Point: Decodable {
    let x: Double
    let y: Double
}

struct Line: Decodable {
    let start: Point
    let end: Point
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
