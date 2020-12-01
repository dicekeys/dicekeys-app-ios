//
//  DiceKeyState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/01.
//

import Foundation
import Combine
import SwiftUI

final class DiceKeyState: ObservableObjectUpdatingOnAllChangesToUserDefaults, Identifiable {
    enum FieldName: String {
        case nickname
        case whatToStore
    }

    enum WhatToStore: String {
        case notSpecified
        case nothing
        case nicknameOnly
        case publicKeys
        case rawDiceKey
    }

    let keyId: String

    // To comply with Identifiable protocol
    var id: String { keyId }

    @UserDefault var nickname: String
    @UserDefault var whatToStoreRaw: String?

    var whatToStore: WhatToStore {
        WhatToStore(rawValue: whatToStoreRaw ?? "") ?? WhatToStore.nothing
    }

    var isDiceKeyStored: Bool {
        whatToStore == .rawDiceKey && EncryptedDiceKeyFileAccessor.instance.hasDiceKey(forKeyId: keyId)
    }

    private func setWhatToStore(_ newValue: WhatToStore) {
        // Ensure this key is on the list of Known DiceKeys
        if newValue == .nothing {
            GlobalState.instance.removeKnownDiceKey(keyId: keyId)
        } else {
            GlobalState.instance.addKnownDiceKey(keyId: keyId)
        }
        // Clean up previous state
        if whatToStore == .rawDiceKey {
            // erase diceKey
            _  = EncryptedDiceKeyFileAccessor.instance.delete(keyId: keyId)
        }

        if whatToStore == .publicKeys {
            // erase public keys
        }

        // Set new state
        self.whatToStoreRaw = newValue.rawValue
        //
    }
    func setStoreRawDiceKey(diceKey: DiceKey) {
        EncryptedDiceKeyFileAccessor.instance.put(diceKey: diceKey) { result in
            switch result {
            case .failure(let error): print(error)
            case .success: break
            }
        }
        self.setWhatToStore(.rawDiceKey)
    }
    func setStoreNicknameOnly() { self.setWhatToStore(.nicknameOnly) }
    func setStorePublicKeys() {
        // FIXME -- write public keys
        self.setWhatToStore(.publicKeys)
    }

    static func fieldKey(_ fieldName: FieldName, _ keyId: String) -> String {
        "keyId: '\(keyId)', field: '\(fieldName.rawValue)'"
    }

    init(forKeyId: String) { // }, defaultNickname: String = "") {
        self.keyId = forKeyId
        self._nickname = UserDefault(DiceKeyState.fieldKey(.nickname, keyId), "")
        self._whatToStoreRaw = UserDefault(DiceKeyState.fieldKey(.whatToStore, keyId), WhatToStore.nothing.rawValue)
        super.init()
    }

    init(_ forDiceKey: DiceKey) {
        let keyId = forDiceKey.id
        self.keyId = keyId
        self._nickname = UserDefault(DiceKeyState.fieldKey(.nickname, keyId), "DiceKey with \(forDiceKey.faces[12].letter.rawValue)\(forDiceKey.faces[12].digit.rawValue) in center")
        self._whatToStoreRaw = UserDefault(DiceKeyState.fieldKey(.whatToStore, keyId), WhatToStore.nothing.rawValue)
        super.init()
        // Force nickname to be written to the stable store
        self.nickname = "\(nickname)"
    }
}
