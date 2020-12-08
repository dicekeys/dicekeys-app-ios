//
//  DiceKey.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation
import CryptoKit

typealias Tuple25<T> = (
    T, T, T, T, T,
    T, T, T, T, T,
    T, T, T, T, T,
    T, T, T, T, T,
    T, T, T, T, T
)

typealias FaceTuple = Tuple25<Face>

let clockwise90DegreeRotationIndexesFor5x5Grid = [
    20, 15, 10, 5, 0,
    21, 16, 11, 6, 1,
    22, 17, 12, 7, 2,
    23, 18, 13, 8, 3,
    24, 19, 14, 9, 4
]

enum IllegalCharacterError: Error {
    case inLetter(position: Int)
    case inDigit(position: Int)
    case inOrientation(position: Int)
}

class DiceKey: Identifiable {
    enum ConstructorError: Error {
        case emptyFace
    }

    let faces: [Face]

    var faceTuple: FaceTuple { get {
        return (
            faces[0], faces[1], faces[2], faces[3], faces[4],
            faces[5], faces[6], faces[7], faces[8], faces[9],
            faces[10], faces[11], faces[12], faces[13], faces[14],
            faces[15], faces[16], faces[17], faces[18], faces[19],
            faces[20], faces[21], faces[22], faces[23], faces[24]
        )
    }}

    init(_ faces: [Face]) {
        precondition(faces.count == 25)
        self.faces = faces
    }

    init(_ facesRead: [FaceRead]) throws {
        precondition(facesRead.count == 25)
        self.faces = try facesRead.map { fr -> Face in
            guard let face = fr.toFace() else {
                throw ConstructorError.emptyFace
            }
            return face
        }
    }
    
    var centerFace: Face { faces[12] }

    static func createFromRandom() -> DiceKey {
        return DiceKey( (1...25).map { _ -> Face in
            return Face(
                letter: FaceLetters[Int.random(in: 0..<(FaceLetters.count))],
                digit: FaceDigits[Int.random(in: 0..<(FaceDigits.count))],
                orientationAsLowercaseLetterTrbl: FaceOrientationLettersTrbl[Int.random(in: 0..<(FaceOrientationLettersTrbl.count))]
            )
        })
    }
    
    static var Example: DiceKey {
        DiceKey((0..<25).map { index in
            Face(
                letter: FaceLetters[index],
                digit: FaceDigits[index % 6],
                orientationAsLowercaseLetterTrbl: FaceOrientationLettersTrbl[index % 4]
            )
        })
    }

    static func createFrom(humanReadableForm: String) throws -> DiceKey {
        precondition(humanReadableForm.count == 50 || humanReadableForm.count == 75)
        let bytesPerFace = humanReadableForm.count == 75 ? 3 : 2
        return DiceKey( try (0...24).map { index -> Face in
            let letterIndex = bytesPerFace * index
            guard let letter = FaceLetter(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: letterIndex)])) else {
                throw IllegalCharacterError.inLetter(position: letterIndex)
            }
            guard let digit = FaceDigit(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: letterIndex + 1)])) else {
                throw IllegalCharacterError.inDigit(position: letterIndex + 1)
            }
            guard let orientationAsLowercaseLetterTrbl = bytesPerFace == 3 ? FaceOrientationLetterTrbl(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: letterIndex + 2)])) :
                FaceOrientationLetterTrbl.Top else {
                throw IllegalCharacterError.inOrientation(position: letterIndex+2)
            }
            return Face(
                letter: letter,
                digit: digit,
                orientationAsLowercaseLetterTrbl: orientationAsLowercaseLetterTrbl
            )
        })
    }

    func withoutOrientations() -> DiceKey {
        return DiceKey(
            faces.map {
                Face(
                    letter: $0.letter,
                    digit: $0.digit,
                    orientationAsLowercaseLetterTrbl: FaceOrientationLetterTrbl.Top
                )
            }
        )
    }

    func rotatedClockwise90Degrees() -> DiceKey {
        return DiceKey(
            clockwise90DegreeRotationIndexesFor5x5Grid.map { index in
                Face(
                    letter: faces[index].letter,
                    digit: faces[index].digit,
                    orientationAsLowercaseLetterTrbl: faces[index].orientationAsLowercaseLetterTrbl.rotate90()
                )
            }
        )
    }

    func toHumanReadableForm(includeOrientations: Bool = true) -> String {
        return faces.map { face -> String in
            face.letter.rawValue +
            face.digit.rawValue +
                (includeOrientations ? face.orientationAsLowercaseLetterTrbl.rawValue : "")
        }.joined(separator: "") as String
    }

    var threeAlternateRotations: [DiceKey] {
        var result: [DiceKey] = [ self.rotatedClockwise90Degrees() ]
        for _ in 1...2 {
            result.append(result[result.count-1].rotatedClockwise90Degrees())
        }
        return result
    }

    var allFourPossibleRotations: [DiceKey] {
        [self] + self.threeAlternateRotations
    }

    func differencesForFixedRotation(compareTo other: DiceKey) -> Int {
        var difference: Int = 0
        for index in 0...24 {
            difference += faces[index].numberOfFieldsDifferent(fromOtherFace: other.faces[index])
        }
        return difference
    }

    func mostSimilarRotationWithDifference(_ other: DiceKey, maxDifferenceToRotateFor: Int = 12) -> ( DiceKey, Int ) {
        var rotationWithSmallestDifference = other
        var smallestDifference = differencesForFixedRotation(compareTo: other)
        if smallestDifference == 0 {
            // no need to look further
            return (rotationWithSmallestDifference, smallestDifference)
        }
        for candidate in other.threeAlternateRotations {
            let difference = differencesForFixedRotation(compareTo: candidate)
            if difference < smallestDifference && difference <= maxDifferenceToRotateFor {
                smallestDifference = difference
                rotationWithSmallestDifference = candidate
            }
            if smallestDifference == 0 {
                // no need to look further
                return (rotationWithSmallestDifference, smallestDifference)
            }
        }
        return (rotationWithSmallestDifference, smallestDifference)
    }

    func mostSimilarRotationOf(_ other: DiceKey, maxDifferenceToRotateFor: Int = 12) -> DiceKey {
        let (rotationWithSmallestDifference, _) = mostSimilarRotationWithDifference(other, maxDifferenceToRotateFor: maxDifferenceToRotateFor)
        return rotationWithSmallestDifference
    }
    
    static func rotationIndependentEquals(_ first: DiceKey?, _ second: DiceKey?) -> Bool {
        guard let a = first, let b = second else { return false }
        let (_, difference) = a.mostSimilarRotationWithDifference(b)
        return difference == 0
    }

    func rotatedToCanonicalForm(
      includeOrientations: Bool = true
    ) -> DiceKey {
        var diceKeyWithEarliestHumanReadableForm = self
        var earliestHumanReadableForm = diceKeyWithEarliestHumanReadableForm.toHumanReadableForm(includeOrientations: includeOrientations)
        for candidateDiceKey in threeAlternateRotations {
            let humanReadableForm = candidateDiceKey.toHumanReadableForm(includeOrientations: includeOrientations)
            if humanReadableForm < earliestHumanReadableForm {
                earliestHumanReadableForm = humanReadableForm
                diceKeyWithEarliestHumanReadableForm = candidateDiceKey
            }
        }
        return diceKeyWithEarliestHumanReadableForm
    }

    var id: String {
        Data(
            SHA256.hash(data: self.toSeed(includeOrientations: true).data(using: .utf8)!)
                .prefix(16)
        ).base64EncodedString()
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "=", with: "")
    }

    func toSeed(includeOrientations: Bool = true) -> String {
        return rotatedToCanonicalForm(includeOrientations: includeOrientations)
            .toHumanReadableForm(includeOrientations: includeOrientations)
    }
}
