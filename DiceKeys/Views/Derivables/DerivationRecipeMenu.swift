//
//  DerivablesMenu.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/11.
//

import SwiftUI

enum DerivationRecipeBuilderType: Equatable {
    case recipe(DerivationRecipe)
    case template(DerivationRecipeTemplate)
    case customFromUrl(DerivationOptionsType)
    case custom
}

struct DerivationRecipeMenu<Content: View>: View {
    let onItemSelected: (DiceKeyPresentPageContent) -> Void
    let label: () -> Content

    init(_ onItemSelected: @escaping (DiceKeyPresentPageContent) -> Void, @ViewBuilder label: @escaping () -> Content) {
        self.onItemSelected = onItemSelected
        self.label = label
    }

    @StateObject private var globalState = GlobalState.instance

    var savedRecipes: [DerivationRecipe] {
        globalState.savedDerivationRecipes
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
                Label("Common password recipes", image: "ellipsis.rectangle")
            })
            Menu(content: {
                VStack {
                    Button("Website password") { choose(.customFromUrl(.Password)) }
                    Button("Other derived value") { choose(.custom) }
                }.scaleEffect(x: 1, y: -1, anchor: .center)
            }, label: {
                Label("Custom recipe", image: "ellipsis")
            })
        }, label: label)
    }
}

//struct DerivablesMenu_Previews: PreviewProvider {
//    static var previews: some View {
//        DerivablesMenu()
//    }
//}
