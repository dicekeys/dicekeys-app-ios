//
//  SavedDiceKeysView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/18.
//

import SwiftUI


import SwiftUI

struct SavedDiceKeysView: View {
    var onDiceKeyLoaded: (DiceKey) -> Void = { diceKey in
        DiceKeyMemoryStore.singleton.setDiceKey(diceKey: diceKey)
    }
    @StateObject var knownDiceKeysStore = KnownDiceKeysStore.singleton
    var maxItemHeight = WindowDimensions.shorterSide / 5

    var knownDiceKeysState: [KnownDiceKeyState] {
        knownDiceKeysStore.knownDiceKeys.map { keyId in KnownDiceKeyState.forKeyId(keyId) }.filter {
            $0.isDiceKeySaved
        }
    }
    
    var body: some View {
        ForEach(knownDiceKeysState) { knownDiceKeyState in
            Button(action: {
                EncryptedDiceKeyFileAccessor.instance.getDiceKey(fromKeyId: knownDiceKeyState.id, centerFace: knownDiceKeyState.centerFace) { result in
                        switch result {
                        case .success(let diceKey):
                            onDiceKeyLoaded(diceKey)
                        default: ()
                    }
                }
            }, label: {
                VStack {
                    if let centerFace = knownDiceKeyState.centerFace {
                        HStack {
                            Spacer()
                            DiceKeyCenterFaceOnlyView(centerFace: centerFace)
                            Spacer()
                        }.frame(
                            maxHeight: maxItemHeight
                        )
                    }
                    Text("Unlock " + knownDiceKeyState.nickname).font(.title2)
                }
            }).buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
}
//struct SavedDiceKeysView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedDiceKeysView()
//    }
//}
