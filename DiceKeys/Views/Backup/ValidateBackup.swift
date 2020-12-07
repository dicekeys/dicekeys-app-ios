//
//  ValidateBackup.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import SwiftUI

struct ValidateBackup: View {
    let target: BackupTarget

    @Binding var originalDiceKey: DiceKey
    @Binding var backupScanned: DiceKey?

    @State var scanningOriginal: Bool = false
    @State var scanningCopy: Bool = false

    var backupDiceKeyRotatedToMatchOriginal: DiceKey? {
        guard let backup = backupScanned else { return nil }
        return originalDiceKey.mostSimilarRotationOf(backup)
    }

    var invalidIndexes: Set<Int> {
        guard let backup = backupDiceKeyRotatedToMatchOriginal else { return Set<Int>() }
        return Set<Int>(
            (0..<25).filter { originalDiceKey.faces[$0].numberOfFieldsDifferent(fromOtherFace: backup.faces[$0]) > 0 }
        )
    }

    var perfectMatch: Bool {
        invalidIndexes.count == 0 && backupScanned != nil
    }

    var totalMismatch: Bool {
        invalidIndexes.count > 5
    }

    var body: some View {
        Instruction("Scan your backup to validate it.")
        Spacer()
        if scanningCopy || scanningOriginal {
            ScanDiceKey { diceKeyScanned in
                if self.scanningOriginal {
                    self.originalDiceKey = diceKeyScanned
                    self.scanningOriginal = false
                } else if self.scanningCopy {
                    self.backupScanned = diceKeyScanned
                    self.scanningCopy = false
                }
            }
            Spacer()
            RoundedTextButton("Cancel") { self.scanningCopy = false }
        } else if let backup = self.backupDiceKeyRotatedToMatchOriginal {
            HStack(alignment: .top) {
                VStack {
                    DiceKeyView(diceKey: originalDiceKey)
                    RoundedTextButton("Re-scan") { self.scanningOriginal = true }.hideIf(perfectMatch)
                }
                Spacer()
                VStack {
                    if totalMismatch {
                        DiceKeyView(diceKey: self.backupScanned!)
                    } else {
                        DiceKeyView(diceKey: backup, highlightIndexes: invalidIndexes)
                    }
                    RoundedTextButton("Re-scan copy") { self.scanningCopy = true }.hideIf(perfectMatch)
                }
            }
            Spacer()
            if perfectMatch {
                HStack {
                    Text("You made a perfect copy!")
                    .font(Font.system(size: 500))
                    .minimumScaleFactor(0.01)
                    .scaledToFit()
                    .lineLimit(1)
                    .foregroundColor(.green)
                }
            } else if totalMismatch {
                Text("That key doesn't look at all like the key you scanned before.").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).foregroundColor(.red)
            } else {
                Text("You incorrectly copied the highlighted \(invalidIndexes.count == 1 ? "die" : "dice"). You can fix the copy to match the original, or change the original to match the copy.").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).foregroundColor(.red)
            }
            Spacer()
        } else {
            HStack(alignment: .top) {
                VStack {
                    if let original = originalDiceKey {
                        DiceKeyView(diceKey: original)
                        RoundedTextButton("Scan DiceKey") { self.scanningOriginal = true }.hidden()
                    } else {
                        Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).offset(x: 0, y: -50)
                        RoundedTextButton("Scan DiceKey") { self.scanningOriginal = true }
                    }
                }
                VStack {
                    Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).offset(x: 0, y: -50)
                    RoundedTextButton("Scan copy to validate") { self.scanningCopy = true }
                }
            }
        }
        Spacer()
    }
}

private struct TestValidateBackup: View {
    @State var originalDiceKey: DiceKey
    @State var backupScanned: DiceKey?

    var body: some View {
        ValidateBackup(target: .DiceKey, originalDiceKey: self.$originalDiceKey, backupScanned: self.$backupScanned)
    }
}

struct ValidateBackup_Previews: PreviewProvider {
    static var previews: some View {
        TestValidateBackup(originalDiceKey: DiceKey.createFromRandom())
    }
}
