//
//  DiceKeyWithDerivedValue.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import SwiftUI
import SeededCrypto
import Combine

struct DiceKeyWithDerivedValue: View {
    let diceKey: DiceKey
    let derivationRecipeBuilder: DerivationRecipeBuilderType

    @StateObject var recipeBuilderState = RecipeBuilderState()

    var diceKeyState: UnlockedDiceKeyState {
        UnlockedDiceKeyState.forDiceKey(diceKey)
    }

//    var derivationRecipeBuilder: DerivationRecipeBuilderType? {
//        switch pageContent {
//        case .Derive(let derivationBuilder): return derivationBuilder
//        default: return nil
//        }
//    }

    var derivationRecipe: DerivationRecipe? {
//        guard let derivationRecipeBuilder = derivationRecipeBuilder else { return nil }
        switch derivationRecipeBuilder {
        case .recipe(let chosenRecipe): return chosenRecipe
        default: return recipeBuilderState.derivationRecipe
        }
    }

    var derivationOptionsJson: String? {
        derivationRecipe?.derivationOptionsJson
    }

    @StateObject private var globalState = GlobalState.instance

    private var savedRecipes: [DerivationRecipe] {
        globalState.savedDerivationRecipes
    }

    private var recipeCanBeSaved: Bool {
        guard let recipe = derivationRecipe else { return false }
        // Requires saving if no saved recipe has the same id
        return savedRecipes.allSatisfy({ $0.id != recipe.id })
    }

    private var recipeCanBeDeleted: Bool {
        guard let recipe = derivationRecipe else { return false }
        return savedRecipes.contains { $0.id == recipe.id }
    }

    var derivedPassword: String? {
        guard derivationRecipe?.type == .Password else { return nil }
        guard let derivationOptionsJson = self.derivationOptionsJson, derivationOptionsJson.count > 0 else { return nil }
        return (try? Password.deriveFromSeed(withSeedString: diceKeyState.diceKey.toSeed(), derivationOptionsJson: derivationOptionsJson).password)
    }

    var derivedValue: String? {
        derivedPassword ?? "(nothing derived)"
    }

    var body: some View {
        VStack {
//            DerivationRecipeMenu({ menuOptionChosen in self.menuOptionChosen = menuOptionChosen }) { Text(derivationRecipe?.name ?? "Derive...") }
            if let derivationRecipeBuilder = self.derivationRecipeBuilder {
                DerivedFromDiceKey(diceKey: diceKeyState.diceKey) {
                    VStack {
                        Text(derivedValue ?? "").multilineTextAlignment(.center)
                    }.padding(.horizontal, 10)
                }//.aspectRatio(contentMode: .fit)
                if derivedValue != "" {
                    Button("Copy") { UIPasteboard.general.string = derivedValue }
                }
                Spacer()
                Form {
                    Section(header: Text("")
//                        DerivationRecipeMenu({ menuOptionChosen in self.menuOptionChosen = menuOptionChosen }) { Text(derivationRecipe?.name ?? "Derive...")
//                            .multilineTextAlignment(.leading)
//                            .frame(minWidth: 2000)
//                        }
                    ) {
                        VStack {
                            DerivationRecipeBuilder(derivableMenuChoice: derivationRecipeBuilder, recipeBuilderState: recipeBuilderState)
                            if let derivationRecipe = derivationRecipe { //} recipeBuilderState.derivationRecipe {
                                Divider()
                                DerivationRecipeView(recipe: derivationRecipe)
                            }
                            Divider()
                            if recipeCanBeSaved {
                                Button(action: { globalState.saveRecipe(derivationRecipe) },
                                   label: { Text("Save recipe in the menu") })//.buttonStyle(PlainButtonStyle())
                            }
                            if recipeCanBeDeleted {
                                Button(action: { globalState.removeRecipe(derivationRecipe) },
                                   label: { Text("Remove recipe from menu") })
                            }
                        }
                    }
                }
            }
            // Spacer()

            Spacer()
        }
        .navigationBarDiceKeyStyle()
    }
}

struct DiceKeyWithDerivedValue_Previews: PreviewProvider {
    init() {
        GlobalState.instance.savedDerivationRecipes = []
    }
    static var previews: some View {
        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        }
        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPhone 11 Max"))
    }
}
