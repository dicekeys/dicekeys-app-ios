//
//  DiceKeyStorageOptions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct DiceKeyStorageOptions: View {
    let diceKey: DiceKey
    @StateObject var diceKeyState: DiceKeyState

    var body: some View {
        VStack {
            Spacer()
            Button(action: { diceKeyState.setStoreNicknameOnly() }) {
                Text("Store only this device's nickname")
            }.disabled( diceKeyState.whatToStore == .nicknameOnly )
            Spacer()
            Button(action: { diceKeyState.setStorePublicKeys() }) {
                Text("Store public keys")
            }.disabled( diceKeyState.whatToStore == .publicKeys )
            Spacer()
            Button(action: { diceKeyState.setStoreRawDiceKey(diceKey: diceKey) }) {
                Text("Store the DiceKey on this device")
            }.disabled( diceKeyState.whatToStore == .rawDiceKey )
            Spacer()
        }
    }
}

struct DiceKeyStorageOptions_Previews: PreviewProvider {
    static let diceKey = DiceKey.createFromRandom()
    @StateObject static var diceKeyState = DiceKeyState(diceKey)

    static var previews: some View {
        DiceKeyStorageOptions(diceKey: diceKey, diceKeyState: DiceKeyStorageOptions_Previews.diceKeyState)
    }
}
