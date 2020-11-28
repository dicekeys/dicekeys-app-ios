//
//  BackupDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct BackupToStickeysPreview {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct BackupDiceKey: View {
    let diceKey: DiceKey
    @State var mode: Mode?

    enum Mode {
        case Stickeys
        case DiceKey
        case Words
    }

    var body: some View {
        if mode == .Stickeys {
            Text("Stickeys!")
        } else {
            VStack {
                Spacer()
                Text("How to backup?")
                Spacer()
                Button(action: { mode = .Stickeys }) {
                    Text("Use Stickeys")
                }
                Spacer()
                Button(action: { mode = .Stickeys }) {
                    Text("Use another DiceKey")
                }
                Spacer()
                Button(action: { mode = .Stickeys }) {
                    Text("Write 30 Words")
                }
                Spacer()
            }
        }
    }
}

struct BackupDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        BackupDiceKey(diceKey: DiceKey.createFromRandom())
    }
}
