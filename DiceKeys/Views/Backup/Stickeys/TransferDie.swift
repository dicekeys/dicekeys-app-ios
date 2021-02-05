//
//  TransferDie.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import SwiftUI

struct TransferDie: View {
    @State var bounds: CGSize = .zero
    let diceKey: DiceKey
    var faceIndex: Int

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            DiceKeyView(diceKey: diceKey, highlightIndexes: Set([faceIndex]))
            Spacer()
            DiceKeyCopyInProgress(diceKey: diceKey, atDieIndex: faceIndex)
        }
    }
}

struct TransferDieInstructions: View {
    let diceKey: DiceKey
    var faceIndex: Int

    var face: Face {
        diceKey.faces[faceIndex]
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Find the \(face.letter.rawValue) die.")
                .font(.title)
                .minimumScaleFactor(0.5)
            if face.orientationAsLowercaseLetterTrbl != .Top {
                Text("Rotate it so the top faces to the \(face.orientationAsLowercaseLetterTrbl.asFacingString).")
                    .font(.title)
                    .minimumScaleFactor(0.5)
            }
            Text("Place it squarely into the hole\( faceIndex == 0 ? " at the top left of the target box" : "").")
                .font(.title)
                .minimumScaleFactor(0.5)
        }
    }
}

struct TransferDie_Previews: PreviewProvider {
    static var previews: some View {
        TransferDie(diceKey: DiceKey.Example, faceIndex: 12)
    }
}
