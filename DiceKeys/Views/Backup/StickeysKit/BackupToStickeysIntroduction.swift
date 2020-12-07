//
//  BackupToStickeys.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/07.
//

import SwiftUI

struct BackupToStickeysIntroduction: View {
    let diceKey: DiceKey

    var body: some View {
        VStack {
            Instruction("Unwrap your Stickeys kit.")
            Spacer()
            HStack {
                VStack(alignment: .center, spacing: 0) {
                    Text("5 Sticker Sheets").font(.title2)
                    StickerSheet()
                }
                Spacer()
                VStack(alignment: .center, spacing: 0) {
                    Text("1 Target Sheet").font(.title2)
                    StickerTargetSheet(diceKey: diceKey)
                }
            }
            Spacer()
            Instruction("Next, you will create a copy of your DiceKey on the target sheet by placing stickers.")
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                Text("Out of Stickeys? You can ")
                Link("order more", destination: URL(string: "https://dicekeys.com/store")!)
                Text(".")
            }.padding(.top, 30)
            Spacer()
        }
    }
}

struct BackupToStickeys_Previews: PreviewProvider {
    static var previews: some View {
        BackupToStickeysIntroduction(diceKey: DiceKey.createFromRandom())
    }
}
