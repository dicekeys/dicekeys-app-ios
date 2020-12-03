//
//  DiceKeyState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import Foundation
import Combine

final class DiceKeyState: ObservableObject {
    let diceKey: DiceKey

    enum FieldName: String {
        case nickname
        case whatToStore
    }

    private static let fileAccessor = EncryptedDiceKeyFileAccessor()

    enum WhatToStore: String {
        case notSpecified
        case nothing
        case nicknameOnly
        case publicKeys
        case rawDiceKey
    }

    let keyId: String

    @Published var nickname: String {
        didSet {
            UserDefaults.standard.set(nickname, forKey: DiceKeyState.fieldKey(.nickname, keyId))
        }
    }

    @Published var whatToStore: WhatToStore {
        willSet {
            if whatToStore == .rawDiceKey {
                // erase diceKey
                _  = EncryptedDiceKeyFileAccessor().delete(keyId: keyId)
            }

            if whatToStore == .publicKeys {
                // erase public keys
            }

            if newValue == .rawDiceKey {
                DiceKeyState.fileAccessor.put(diceKey: diceKey) { result in
                    switch result {
                    case .failure(let error): print(error)
                    case .success: break
                    }
                }
            } else if newValue == .publicKeys {
                //
            }
        }
        didSet {
            UserDefaults.standard.set(nickname, forKey: DiceKeyState.fieldKey(.nickname, keyId))
        }
    }

    static func fieldKey(_ fieldName: FieldName, _ keyId: String) -> String {
        "keyId: '\(keyId)', field: '\(fieldName.rawValue)'"
    }

    let objectWillChange = ObservableObjectPublisher()
    private var notificationSubscription: AnyCancellable?

//    init(forKeyId: String, defaultNickname: String = "My DiceKey FIXME") {
//    }

    // convenience
    init(_ forDiceKey: DiceKey) {
        self.diceKey = forDiceKey
        let defaultNickname = "DiceKey with \(forDiceKey.faces[12].letter.rawValue)\(forDiceKey.faces[12].digit.rawValue) in center"

        self.keyId = diceKey.id
        self.nickname = UserDefaults.standard.string(forKey: DiceKeyState.fieldKey(.nickname, keyId)) ?? defaultNickname
        self.whatToStore = WhatToStore(rawValue: UserDefaults.standard.string(forKey: DiceKeyState.fieldKey(.whatToStore, keyId)) ?? "") ?? WhatToStore.nothing

        notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
            self.objectWillChange.send()
        }
    }
}
