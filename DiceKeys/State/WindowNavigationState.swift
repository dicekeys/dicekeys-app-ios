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
    
    @Published var showLoadDiceKey: Bool = false { didSet { self.sendChangeEventOnMainThread()} }
    @Published var showAssemblyInstructions: Bool = false { didSet { self.sendChangeEventOnMainThread()} }

//    @Published var topLevelNavigation: TopLevelNavigateTo = .nowhere {
//        didSet { self.sendChangeEventOnMainThread() }
//    }
}
