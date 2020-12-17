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
                FormCard(title: "Recipe\( derivationRecipe == nil ? "" : " for \( derivationRecipe?.name ?? "" )")") {
                    VStack(alignment: .leading) {
                        if derivationRecipeBuilder.isBuilder {
                            Section(header: Text("Settings").font(.title2) ) {
                                DerivationRecipeBuilder(derivableMenuChoice: derivationRecipeBuilder, recipeBuilderState: recipeBuilderState)
                            }
                        }
                        if let derivationRecipe = derivationRecipe { //} recipeBuilderState.derivationRecipe {
                            Divider()
                            Section(header: Text("Internal representation of your recipe").font(.title3) ) {
                                DerivationRecipeView(recipe: derivationRecipe)
                            }
                        }
                        Divider()
                        HStack {
                            Spacer()
                            if recipeCanBeSaved {
                                Button(action: { globalState.saveRecipe(derivationRecipe) },
                                   label: { Text("Save recipe in the menu") })//.buttonStyle(PlainButtonStyle())
                            }
                            if recipeCanBeDeleted {
                                Button(action: { globalState.removeRecipe(derivationRecipe) },
                                   label: { Text("Remove recipe from menu") })
                            }
                            Spacer()
                        }
                    }
                }.padding(.horizontal, 10).padding(.vertical, 10)
            }
            // Spacer()

            Spacer()
        }
        .navigationBarDiceKeyStyle()
    }
}

struct FormCard<Content: View, TitleContent: View>: View {
    let title: () -> TitleContent
    let content: () -> Content

    init(title: @escaping () -> TitleContent, content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        RoundedRectCard(backgroundRectColor: Color.formHeadingBackground, radius: 10, horizontalMargin: 5, verticalMargin: 5) {
            VStack(alignment: .leading, spacing: 0) {
                title().padding(.leading, 10)
                RoundedRectCard(backgroundRectColor: Color.formContentBackground, radius: 10, horizontalMargin: 10, verticalMargin: 6) {
                    content()
                }.padding(.all, 5)
            }
        }
    }
}

extension FormCard where TitleContent == Text {
    init(title: String, content: @escaping () -> Content) {
        self.init(title: { Text(title).font(.title).foregroundColor(Color.formHeadingForeground) }, content: content)
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
