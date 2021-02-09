//
//  DerivationRecipeStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation

final class DerivationRecipeStore: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private(set) var singleton = DerivationRecipeStore()

    static let fieldNameSavedDerivationRecipes: String = "savedDerivationRecipes"
    @UserDefault(fieldNameSavedDerivationRecipes, "") private var savedDerivationRecipesJson: String

    var savedDerivationRecipes: [DerivationRecipe] {
        get {
            return savedDerivationRecipesJson == "" ? [] :
                (try? DerivationRecipe.listFromJson(savedDerivationRecipesJson)) ?? []
        } set {
            if let derivablesJson = try? DerivationRecipe.listToJson(newValue) {
                self.savedDerivationRecipesJson = derivablesJson
                self.sendChangeEventOnMainThread()
            }
        }
    }

    func saveRecipe(_ recipeToSave: DerivationRecipe?) {
        guard let recipe = recipeToSave else { return }
        if savedDerivationRecipes.allSatisfy({ $0.id != recipe.id }) {
            self.savedDerivationRecipes = (
                self.savedDerivationRecipes + [recipe]
            )
            .sorted(by: { a, b in a.id < b.id })
            self.sendChangeEventOnMainThread()
        }
    }

    func removeRecipe(_ recipeId: String) {
        self.savedDerivationRecipes = savedDerivationRecipes.filter { $0.id != recipeId }
    }
    func removeRecipe(_ recipe: DerivationRecipe?) {
        if let recipeId = recipe?.id {
            removeRecipe(recipeId)
        }
    }
}

