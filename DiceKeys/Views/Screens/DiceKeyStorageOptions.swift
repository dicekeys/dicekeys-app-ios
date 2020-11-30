//
//  DiceKeyStorageOptions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct DiceKeyStorageOptions: View {
    @StateObject var diceKeyState: DiceKeyState

    var body: some View {
        VStack {

            Spacer()
            Button(action: { diceKeyState.whatToStore = .nicknameOnly }) {
                Text("Store only this device's nickname")
            }.disabled( diceKeyState.whatToStore == .nicknameOnly )
            Spacer()
            Button(action: { diceKeyState.whatToStore = .publicKeys }) {
                Text("Store public keys")
            }.disabled( diceKeyState.whatToStore == .publicKeys )
            Spacer()
            Button(action: { diceKeyState.whatToStore = .rawDiceKey }) {
                Text("Store the DiceKey on this device")
            }.disabled( diceKeyState.whatToStore == .rawDiceKey )
            Spacer()
        }
    }
}

struct DiceKeyStorageOptions_Previews: PreviewProvider {
    // let diceKey = DiceKey.createFromRandom()
    @StateObject static var diceKeyState = DiceKeyState(DiceKey.createFromRandom())

    static var previews: some View {
        DiceKeyStorageOptions(diceKeyState: DiceKeyStorageOptions_Previews.diceKeyState)
    }
}
