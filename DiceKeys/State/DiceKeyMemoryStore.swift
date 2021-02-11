//
//  DiceKeyMemoryStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation

final class DiceKeyMemoryStore: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private(set) var singleton = DiceKeyMemoryStore()
    
    /// The app should always use the singleton and never use this constructor directly.
    /// It exists eexclusively for the purpose of allowing previews and tests to create
    /// different test memory store states.
    init(_ diceKeyLoaded: DiceKey? = nil) {
        self.diceKeyLoaded = diceKeyLoaded
    }

    @Published var diceKeyLoaded: DiceKey? = nil {
        didSet { self.sendChangeEventOnMainThread() }
    }
    
    func setDiceKey(diceKey: DiceKey) {
        self.diceKeyLoaded = diceKey
    }
    
    func clearDiceKey() {
        self.diceKeyLoaded = nil
    }
    
    private var cachedDiceKeyState: UnlockedDiceKeyState? = nil
    var diceKeyState: UnlockedDiceKeyState? {
        if (cachedDiceKeyState?.diceKey != self.diceKeyLoaded) {
            if let diceKey = diceKeyLoaded {
                cachedDiceKeyState = UnlockedDiceKeyState(diceKey: diceKey)
            } else {
                cachedDiceKeyState = nil
            }
        }
        return cachedDiceKeyState
    }
}