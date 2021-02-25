//
//  SavedDiceKeysView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/18.
//

import SwiftUI

/// This view shows the list of DiceKeys saved in the keychain and provides the ability to
/// unlock (open) them.
struct SavedDiceKeysView: View {
    @StateObject var diceKeyMemoryStore: DiceKeyMemoryStore = DiceKeyMemoryStore.singleton
    @StateObject var knownDiceKeysStore = KnownDiceKeysStore.singleton
    var saveCallback: ((_ diceKey: DiceKey) -> Void)?

    var onDiceKeyLoaded: (DiceKey) -> Void = { diceKey in
        DiceKeyMemoryStore.singleton.setDiceKey(diceKey: diceKey)
    }
    var maxItemHeight = WindowDimensions.shorterSide / 5
    
    
    var diceKeysStoredInMemory: [DiceKey] { diceKeyMemoryStore.allDiceKeys }
    
    var idsOfDiceKeysStoredInMemory: Set<String> {
        Set( diceKeysStoredInMemory.map{ k in k.id })
    }
    
    var metadataForDiceKeysOnlyStoredEncrypted: [StoredEncryptedDiceKeyMetadata] {
        let idsOfDiceKeysStoredInMemory = self.idsOfDiceKeysStoredInMemory
        return knownDiceKeysStore.knownDiceKeys.map { keyId in StoredEncryptedDiceKeyMetadata.forKeyId(keyId)
            }.filter {
                // Do not include keys already loaded into memory
                !idsOfDiceKeysStoredInMemory.contains($0.keyId) &&
                // Include only those keys that can be read from encrypted storage
                $0.isDiceKeyStored
            }.sorted{
                $0.centerFaceInHumanReadableForm < $1.centerFaceInHumanReadableForm
            }
    }
    
    var body: some View {
        if (diceKeyMemoryStore.isCountdownTimerRunning) {
            Text("Keys will locked/\( diceKeyMemoryStore.formattedTimeRemaining )")
        }
        ForEach(diceKeysStoredInMemory) { diceKeyStoredInMemory in
            Button(action: {
                onDiceKeyLoaded(diceKeyStoredInMemory)
            }, label: {
                VStack {
                    HStack {
                        Spacer()
                        DiceKeyView(diceKey: diceKeyStoredInMemory)
                        Spacer()
                    }
                    Text("Open " + diceKeyStoredInMemory.nickname).font(.title2)
                    // Text("\(EncryptedDiceKeyStore.hasDiceKey(forKeyId: knownDiceKeysState.keyId) ? "Locking" : "Forgetting") in \(diceKeyMemoryStore.formattedTimeRemaining)")"
                }.frame(maxHeight: maxItemHeight)
            }).buttonStyle(PlainButtonStyle())
            if case .keysNeverExpire = diceKeyMemoryStore.memoryStoreExpirationState {
                Text("\( EncryptedDiceKeyStore.hasDiceKey(forKeyId: diceKeyStoredInMemory.id) ? "Unlocked" : "Open") until the app is closed")
            } else if EncryptedDiceKeyStore.hasDiceKey(forKeyId: diceKeyStoredInMemory.id) {
                if (diceKeyMemoryStore.isCountdownTimerRunning) {
                    Text("Locking in \( diceKeyMemoryStore.formattedTimeRemaining )")
                }
            } else if let saveCallback = self.saveCallback {
                if (diceKeyMemoryStore.isCountdownTimerRunning) {
                    Text("Erasing in \( diceKeyMemoryStore.formattedTimeRemaining )")
                }
                Button("Save this DiceKey", action: { saveCallback(diceKeyStoredInMemory) })
            }
            
            Spacer()

        }
        ForEach(metadataForDiceKeysOnlyStoredEncrypted) { knownDiceKeyState in
            Button(action: {
                EncryptedDiceKeyStore.getDiceKey(fromKeyId: knownDiceKeyState.id, centerFace: knownDiceKeyState.centerFace) {
                    if case .success(let diceKey) = $0 {
                        onDiceKeyLoaded(diceKey)
                    }
                }
            }, label: {
                VStack {
                    if let centerFace = knownDiceKeyState.centerFace {
                        HStack {
                            Spacer()
                            DiceKeyCenterFaceOnlyView(centerFace: centerFace)
                            Spacer()
                        }
                    }
                    if (diceKeyMemoryStore.isEmpty || !diceKeyMemoryStore.contains(knownDiceKeyState.keyId)) {
                        Text("Unlock " + knownDiceKeyState.nickname).font(.title2)
                    } else {
                        Text("Open " + knownDiceKeyState.nickname).font(.title2)
                        // Text("\(EncryptedDiceKeyStore.hasDiceKey(forKeyId: knownDiceKeysState.keyId) ? "Locking" : "Forgetting") in \(diceKeyMemoryStore.formattedTimeRemaining)")"
                    }
                }.frame(maxHeight: maxItemHeight)
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
