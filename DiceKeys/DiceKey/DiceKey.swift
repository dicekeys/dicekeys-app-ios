//
//  DiceKey.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

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

class DiceKey {
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

    static func createFromRandom() -> DiceKey {
        return DiceKey( (1...25).map { _ -> Face in
            return Face(
                letter: FaceLetters[Int.random(in: 0..<(FaceLetters.count))],
                digit: FaceDigits[Int.random(in: 0..<(FaceDigits.count))],
                orientationAsLowercaseLetterTrbl: FaceOrientationLettersTrbl[Int.random(in: 0..<(FaceOrientationLettersTrbl.count))]
            )
        })
    }

    static func createFrom(humanReadableForm: String) throws -> DiceKey {
        precondition(humanReadableForm.count == 50 || humanReadableForm.count == 75)
        let bytesPerFace = humanReadableForm.count == 75 ? 3 : 2
        return DiceKey( try (0...24).map { index -> Face in
            let letterIndex = bytesPerFace * index
            let letter = FaceLetter(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: letterIndex)]))
            if letter == nil {
                throw IllegalCharacterError.inLetter(position: letterIndex)
            }
            let digit = FaceDigit(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: letterIndex + 1)]))
            if digit == nil {
                throw IllegalCharacterError.inDigit(position: letterIndex + 1)
            }
            let orientationAsLowercaseLetterTrbl = bytesPerFace == 3 ? FaceOrientationLetterTrbl(rawValue: String(humanReadableForm[humanReadableForm.index(humanReadableForm.startIndex, offsetBy: letterIndex + 2)])) :
                FaceOrientationLetterTrbl.Top
            if orientationAsLowercaseLetterTrbl == nil {
                throw IllegalCharacterError.inOrientation(position: letterIndex+2)
            }
            return Face(
                letter: letter!,
                digit: digit!,
                orientationAsLowercaseLetterTrbl: orientationAsLowercaseLetterTrbl!
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

    func toHumanReadableForm(includeOrientations: Bool) -> String {
        return faces.map { face -> String in
            face.letter.rawValue +
            face.digit.rawValue +
                (includeOrientations ? face.orientationAsLowercaseLetterTrbl.rawValue : "")
        }.joined(separator: "") as String
    }

    func rotatedToCanonicalForm(
      includeOrientations: Bool
    ) -> DiceKey {
        var candidateDiceKey = self
        var diceKeyWithEarliestHumanReadableForm = candidateDiceKey
        var earliestHumanReadableForm = diceKeyWithEarliestHumanReadableForm.toHumanReadableForm(includeOrientations: includeOrientations)
        for _ in 1...3 {
            candidateDiceKey = candidateDiceKey.rotatedClockwise90Degrees()
            let humanReadableForm = candidateDiceKey.toHumanReadableForm(includeOrientations: includeOrientations)
            if humanReadableForm < earliestHumanReadableForm {
                earliestHumanReadableForm = humanReadableForm
                diceKeyWithEarliestHumanReadableForm = candidateDiceKey
            }
        }
        return diceKeyWithEarliestHumanReadableForm
    }

    func toSeed(includeOrientations: Bool) -> String {
        return rotatedToCanonicalForm(includeOrientations: includeOrientations)
            .toHumanReadableForm(includeOrientations: includeOrientations)
    }
}
