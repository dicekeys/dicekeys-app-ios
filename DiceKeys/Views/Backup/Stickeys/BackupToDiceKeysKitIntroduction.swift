//
//  BackupToDiceKeysKitIntroduction.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import SwiftUI

struct BackupToDiceKeysKitIntroduction: View {
    let diceKey: DiceKey

    var body: some View {
        VStack {
            Spacer()
            Instruction("Open your DiceKey kit and take out the box bottom and the 25 dice.", lineLimit: 3)
            Spacer()
            DiceKeyView(diceKey: diceKey, showDiceAtIndexes: Set()).frame(maxWidth: WindowDimensions.shorterSide / 6, maxHeight: WindowDimensions.shorterSide / 2)
            Spacer()
            Instruction("Next, you will replicate the first DiceKey by copying the arrangement of dice.", lineLimit: 3)
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                Text("Need another DiceKey? You can ")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Link("order more", destination: URL(string: "https://dicekeys.com/store")!)
                Text(".")
            }.padding(.top, 30)
            Spacer()
        }
    }
}

struct BackupToDiceKeysKitIntroduction_Previews: PreviewProvider {
    static var previews: some View {
        BackupToDiceKeysKitIntroduction(diceKey: DiceKey.createFromRandom())
    }
}
