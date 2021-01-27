//
//  DiceKey.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation
import SeededCrypto

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

    /// The 25 faces that make up a DiceKey, each with a letter, digit, and orientation
    let faces: [Face]

    /// The set of faces as a more formally-defined 25-item Tuple
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
    
    /// The center face of a DiceKey, useful as the most salient face for users to
    /// associate with the key.
    var centerFace: Face { faces[12] }

    /// Creae a DiceKey from a low-quality random number generator for testing purposes
    /// (not for cryptographic-quality DiceKey production)
    static func createFromRandom() -> DiceKey {
        return DiceKey( (1...25).map { _ -> Face in
            return Face(
                letter: FaceLetters[Int.random(in: 0..<(FaceLetters.count))],
                digit: FaceDigits[Int.random(in: 0..<(FaceDigits.count))],
                orientationAsLowercaseLetterTrbl: FaceOrientationLettersTrbl[Int.random(in: 0..<(FaceOrientationLettersTrbl.count))]
            )
        })
    }
    
    /// A sample DiceKey for use in development, such as generating sample views
    static var Example: DiceKey {
        DiceKey((0..<25).map { index in
            Face(
                letter: FaceLetters[index],
                digit: FaceDigits[index % 6],
                orientationAsLowercaseLetterTrbl: FaceOrientationLettersTrbl[index % 4]
            )
        })
    }

    /// Re-construct a DiceKey from human-readable form.
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

    /// Returns a DiceKey stripped of all so that all dice are facing upright (top)
    /// (non-mutating)
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

    /// Returns a DiceKey rotated 90 degrees clockwise (non-mutating)
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

    /// Convert the DiceKey to human-readable form of
    /// letter, digit, orientation triples
    func toHumanReadableForm(includeOrientations: Bool = true) -> String {
        return faces.map { face -> String in
            face.letter.rawValue +
            face.digit.rawValue +
                (includeOrientations ? face.orientationAsLowercaseLetterTrbl.rawValue : "")
        }.joined(separator: "") as String
    }

    /// A 3-element array containing the 3 possible alternate orientations
    /// of a DiceKey
    private var threeAlternateRotations: [DiceKey] {
        var result: [DiceKey] = [ self.rotatedClockwise90Degrees() ]
        for _ in 1...2 {
            result.append(result[result.count-1].rotatedClockwise90Degrees())
        }
        return result
    }

    /// A four-element array of the four possible rotations/orientations of a DiceKey
    private var allFourPossibleRotations: [DiceKey] {
        [self] + self.threeAlternateRotations
    }

    /// Count the number of fields different between two DiceKeys.
    /// For each of the 25 faces, there are three possible differences
    /// (letter, digit, and orientation)
    /// (does not rotate the DiceKeys)
    private func differencesForFixedRotation(compareTo other: DiceKey) -> Int {
        var difference: Int = 0
        for index in 0...24 {
            difference += faces[index].numberOfFieldsDifferent(fromOtherFace: other.faces[index])
        }
        return difference
    }

    /// Get the difference between this DiceKey and another DiceKey, rotating the other DiceKey
    /// as necessary to get a minimal distance betweeen them.
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

    /// Find the rotation of the other DiceKey that is most similar to the current one,
    /// which is useful when summarizing the minimal difference between two DiceKeys.
    func mostSimilarRotationOf(_ other: DiceKey, maxDifferenceToRotateFor: Int = 12) -> DiceKey {
        let (rotationWithSmallestDifference, _) = mostSimilarRotationWithDifference(other, maxDifferenceToRotateFor: maxDifferenceToRotateFor)
        return rotationWithSmallestDifference
    }
    
    // Compare two DiceKeys to see if they will generate the same cryptographic seed
    static func rotationIndependentEquals(_ first: DiceKey?, _ second: DiceKey?) -> Bool {
        guard let a = first, let b = second else { return false }
        let (_, difference) = a.mostSimilarRotationWithDifference(b)
        return difference == 0
    }

    /// Rotate to canonical orientation by finding the one of the four possible orientations
    /// that has the human-readable form with the earliest utf8 sort order.
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
    
    private let recipeFor16ByteUniqueIdentifier = "{\"purpose\":\"a unique identifier for this DiceKey\",\"lengthInBytes\":16}"

    /// A 16-byte unique identifier for this DiceKey derived via hashing
    var idBytes: Data {
        try! Secret.deriveFromSeed(withSeedString: toSeed(), derivationOptionsJson: recipeFor16ByteUniqueIdentifier).secretBytes()
    }

    /// A url-safe base64 encoded 16-byte unique identifier for this DiceKey derived via hashing
    var id: String {
        idBytes
        .base64EncodedString()
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "=", with: "")
    }

    /// Turn the DiceKey into a cryptographic seed by rotating it to the canonical
    /// orientation and then generating its human-readable form
    func toSeed(includeOrientations: Bool = true) -> String {
        return rotatedToCanonicalForm(includeOrientations: includeOrientations)
            .toHumanReadableForm(includeOrientations: includeOrientations)
    }
}
