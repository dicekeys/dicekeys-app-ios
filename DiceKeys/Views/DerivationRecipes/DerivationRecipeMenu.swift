//
//  DerivablesMenu.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/11.
//

import SwiftUI

enum DerivationRecipeBuilderType: Equatable {
    case recipe(DerivationRecipe)
    case template(DerivationRecipe)
    case customFromUrl(SeededCryptoRecipeType)
//    case custom

    var isRecipe: Bool {
        switch self {
        case .recipe: return true
        default: return false
        }
    }

    var isBuilder: Bool {
        switch self {
        case .template: return true
        case .customFromUrl: return true
        case .recipe: return false
//        default: return false
        }
    }
}
