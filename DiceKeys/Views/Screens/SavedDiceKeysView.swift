//
//  SavedDiceKeysView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/18.
//

import SwiftUI

private struct DiceKeyInMemory: View {
    @StateObject var diceKeyMemoryStore: DiceKeyMemoryStore = DiceKeyMemoryStore.singleton
    let diceKey: DiceKey
    var saveCallback: ((_ diceKey: DiceKey) -> Void)?
    var onDiceKeySelected: ((DiceKey) -> Void)?
    
    var isInEncryptedDataStore: Bool {
        EncryptedDiceKeyStore.hasDiceKey(forKeyId: self.diceKey.id)
    }
    
    var isCountdownRunning: Bool {
        diceKeyMemoryStore.isCountdownTimerRunning
    }
    
    var expirationActionText: String {
        self.isInEncryptedDataStore ? "Lock" : "Erase"
    }
    
    var extensionActionText: String {
        isCountdownRunning ? "Add" : "\(expirationActionText) in"
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Button(action: {
                onDiceKeySelected?(diceKey)
            }, label: {
                VStack {
                    HStack {
                        Spacer()
                        DiceKeyView(diceKey: self.diceKey)
                        Spacer()
                    }
                    Text(diceKey.nickname).font(.title2)
                }
            }).buttonStyle(PlainButtonStyle())
            HStack {
                if case .keysNeverExpire = diceKeyMemoryStore.memoryStoreExpirationState {
                    Text("\( EncryptedDiceKeyStore.hasDiceKey(forKeyId: diceKey.id) ? "Unlocked" : "Will not be erased") until the app is closed")
                } else if isCountdownRunning {
                    Text("\( self.isInEncryptedDataStore ? "Locking" : "Erasing" ) in \( diceKeyMemoryStore.formattedTimeRemaining )")
                }
                Menu(content: {
                    if let saveCallback = self.saveCallback, !self.isInEncryptedDataStore {
                        Button("Save this DiceKey", action: { saveCallback(diceKey) })
                        Spacer(minLength: 20)
                    }
                    if (isCountdownRunning) {
                        Button("\(self.extensionActionText) five minutes", action: { diceKeyMemoryStore.extendDeadlineBy(seconds: 5 * 60) })
                        Button("\(self.extensionActionText) one hour", action: { diceKeyMemoryStore.extendDeadlineBy(seconds: 60 * 60) })
                        Button("Keep keys in memory until I quit", action: { diceKeyMemoryStore.setKeysNeverExpire() })
                        Spacer(minLength: 20)
                    }
                    Button("\(expirationActionText) Immediately", action: { diceKeyMemoryStore.expireKey(self.diceKey) })

                }, label: { Image(systemName: "ellipsis") })
            }.padding(.top, 10).padding(.bottom, 10)
        }
    }
}

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
        ForEach(diceKeysStoredInMemory) { diceKeyStoredInMemory in
            DiceKeyInMemory(
                diceKey: diceKeyStoredInMemory,
                saveCallback: self.saveCallback,
                onDiceKeySelected: { self.onDiceKeyLoaded($0) }
            ).frame(maxHeight: maxItemHeight)
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
