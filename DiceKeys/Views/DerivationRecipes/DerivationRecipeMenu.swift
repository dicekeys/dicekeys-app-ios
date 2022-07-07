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

// Deprecated
struct DerivationRecipeMenu<Content: View>: View {
    let onItemSelected: (DiceKeyPresentPageContent) -> Void
    let label: () -> Content

    init(_ onItemSelected: @escaping (DiceKeyPresentPageContent) -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.onItemSelected = onItemSelected
        self.label = label
    }

    @EnvironmentObject private var recipeStore: DerivationRecipeStore

    var savedRecipes: [DerivationRecipe] {
        recipeStore.savedDerivationRecipes
    }

    var passwordDerivables: [DerivationRecipe] {
        savedRecipes.filter { $0.type == .Password }
    }

    func choose(_ choice: DerivationRecipeBuilderType) {
        self.onItemSelected(.Derive((choice)))
    }

    var body: some View {
        Menu(content: {
            if passwordDerivables.count > 0 {
                ForEach(passwordDerivables) { recipe in
                    Button(action: { choose(DerivationRecipeBuilderType.recipe(recipe)) }) {
                        Text(recipe.name)
                    }
                }
            }
            Menu(content: {
                VStack {
                    ForEach(derivablePasswordTemplates) { template in
                        Button(template.name) { choose(DerivationRecipeBuilderType.template(template)) }
                    }
                }.scaleEffect(x: 1, y: -1, anchor: .center)
            }, label: {
                Label("Common password recipes", systemImage: "ellipsis.rectangle")
            })
            Menu(content: {
                VStack {
                    Button("Online password") { choose(.customFromUrl(.Password)) }
//                    Button("Other derived value") { choose(.custom) }
                }.scaleEffect(x: 1, y: -1, anchor: .center)
            }, label: {
                Label("Custom recipe", systemImage: "ellipsis")
            })
        }, label: label)
    }
}

//struct DerivablesMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        DerivablesMenu()
//    }
//}
