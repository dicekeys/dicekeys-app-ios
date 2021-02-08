//
//  WindowNavigationState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/07.
//

import Foundation

enum TopLevelNavigateTo {
    case nowhere
    case loadDiceKey
    case diceKeyPresent
    case assemblyInstructions
}

final class WindowNavigationState: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private(set) var singleton = WindowNavigationState()
    
    @Published var topLevelNavigation: TopLevelNavigateTo = .nowhere {
        didSet { self.sendChangeEventOnMainThread() }
    }
}
