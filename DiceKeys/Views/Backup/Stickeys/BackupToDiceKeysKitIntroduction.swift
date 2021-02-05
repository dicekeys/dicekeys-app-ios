//
//  BackupToDiceKeysKitIntroduction.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import SwiftUI

struct BackupToDiceKeysKitIntroduction: View {
    let diceKey: DiceKey
    #if os(iOS)
    let shorterSide = UIScreen.main.bounds.size.shorterSide
    #else
    let shorterSide = NSScreen.main!.frame.size.height
    #endif

    var body: some View {
        VStack {
            Spacer()
            Instruction("Open your DiceKey kit and take out the box bottom and the 25 dice.", lineLimit: 3)
            Spacer()
            DiceKeyView(diceKey: diceKey, showDiceAtIndexes: Set()).padding(.horizontal, shorterSide / 6)
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
