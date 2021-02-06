//
//  KnownDiceKeysStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/07.
//

import Foundation

struct KnownDiceKeyIdentifiable: Identifiable {
    let id: String
}

final class KnownDiceKeysStore: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private let knownDiceKeysFieldName = "knownDiceKeys"
    
    static private(set) var singleton = KnownDiceKeysStore()

    @UserDefault(knownDiceKeysFieldName, []) private(set) var knownDiceKeys: [String]

    func addKnownDiceKey(keyId: String) {
        if !knownDiceKeys.contains(keyId) {
            self.knownDiceKeys = knownDiceKeys + [keyId]
        }
    }
    func removeKnownDiceKey(keyId: String) {
        self.knownDiceKeys = knownDiceKeys.filter { $0 != keyId }
    }

    var knownDiceKeysIdentifiable: [KnownDiceKeyIdentifiable] {
        knownDiceKeys.map { KnownDiceKeyIdentifiable(id: $0) }
    }
}
