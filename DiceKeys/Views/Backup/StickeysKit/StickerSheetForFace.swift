//
//  Stic.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import Foundation
import SwiftUI

struct StickerSheetForFace {
    let face: Face

    private var letterIndexOfFirstColumn: Int {
        Int((faceLetterIndexes[face.letter]! / 5) * 5)
    }
    var firstLetter: FaceLetter {
        FaceLetters[ letterIndexOfFirstColumn ]
    }
    var lastLetter: FaceLetter {
        FaceLetters[ letterIndexOfFirstColumn + 4 ]
    }

    var column: CGFloat {
        CGFloat(faceLetterIndexes[face.letter]! % 5)
    }
    var row: CGFloat {
        CGFloat(faceDigitIndexes[face.digit]!)
    }
}
