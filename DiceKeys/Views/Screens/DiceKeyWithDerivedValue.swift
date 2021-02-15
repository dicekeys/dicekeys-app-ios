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
        guard case let .ready(derivationRecipe) = recipeBuilderState.progress else { return nil }
            return derivationRecipe
    }

    var recipe: String? {
        derivationRecipe?.recipe
    }

    @StateObject private var recipeStore = DerivationRecipeStore.singleton

    private var savedRecipes: [DerivationRecipe] {
        recipeStore.savedDerivationRecipes
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
        guard let recipe = self.recipe, recipe.count > 0 else { return nil }
        guard let seed = DiceKeyMemoryStore.singleton.diceKeyLoaded?.toSeed() else { return nil }
        let password = try? Password.deriveFromSeed(withSeedString: seed, recipe: recipe).password
        return (password)
    }

    var derivedValue: String? {
        derivedPassword ?? "(nothing derived)"
    }

    var body: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0) {
           if let derivationRecipeBuilder = self.derivationRecipeBuilder {
                FormCard(title: "Recipe\( derivationRecipe == nil ? "" : " for \( derivationRecipe?.name ?? "" )")") {
                    VStack(alignment: .leading) {
                        if derivationRecipeBuilder.isBuilder {
                            DerivationRecipeBuilder(derivableMenuChoice: derivationRecipeBuilder, recipeBuilderState: recipeBuilderState)
                        }
                        Divider().hideIf(derivationRecipe == nil)
                        Text("Internal representation of your recipe").hideIf(derivationRecipe == nil)
                            .font(.title3)
                            .scaledToFit()
                            .minimumScaleFactor(0.01)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                        DerivationRecipeView(recipeBuilderProgress: self.recipeBuilderState.progress).padding(.top, 3)
                        Divider()
                        HStack {
                            Spacer()
                            Button(action: {
                                if recipeCanBeDeleted {
                                    recipeStore.removeRecipe(derivationRecipe)
                                } else if recipeCanBeSaved {
                                    recipeStore.saveRecipe(derivationRecipe)
                                }
                            }, label: { Text(recipeCanBeDeleted ? "Remove recipe from menu" : "Save recipe in the menu")
                            }).showIf(recipeCanBeSaved || recipeCanBeDeleted)
                            Spacer()
                        }
                    }
                }.padding(.horizontal, 10)
                .layoutPriority(1)
                Spacer()
                VStack(alignment: .center, spacing: 0) {
                    DerivedFromDiceKey(diceKey: diceKeyState.diceKey, content: {
                            Text(derivedValue ?? "")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.1)
                                .fixedSize(horizontal: false, vertical: true)
//                                .padding(.horizontal, 5)
                    }).padding(.horizontal, 5).layoutPriority(-1)
                    if let derivedValue = derivedValue, derivedValue != "" {
                        Button("Copy\( derivationRecipe?.type == .Password ? " Password" : "" )") {
                            #if os(iOS)
                            UIPasteboard.general.string = derivedValue
                            #else
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                            pasteboard.setString(derivedValue, forType: .string)
                            #endif
                        }
                    }
                }.hideIf(derivationRecipe == nil)
                Spacer()
            }
            // Spacer()

            Spacer()
        }
    }
}

struct FormCard<Content: View, TitleContent: View>: View {
    let content: () -> Content

    private var titleViewBuilder: (() -> TitleContent)?
    private var titleString: String?

    init(title: @escaping () -> TitleContent, content: @escaping () -> Content) {
        self.titleViewBuilder = title
        self.content = content
    }

    var body: some View {
        RoundedRectCard(backgroundRectColor: Color.formHeadingBackground, radius: 10 //, // topMargin: 0, bottomMargin: 10, horizontalMargin: 5
        ) {
            VStack(alignment: .leading, spacing: 0) {
                if let titleViewBuilder = self.titleViewBuilder {
                    titleViewBuilder().padding(.leading, 10)
                } else if let titleString = self.titleString {
                    Text(titleString)
                        .font(.title)
                        .foregroundColor(Color.formHeadingForeground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.01)
//                        .scaledToFit()
                        .padding(.horizontal, 10)
                }
                RoundedRectCard(backgroundRectColor: Color.formContentBackground, radius: 10 //, topMargin: 2, bottomMargin: 5, horizontalMargin: 10
                ) {
                    content()
                }
            }
        }
    }
}

extension FormCard where TitleContent == Text {
    init(title: String, content: @escaping () -> Content) {
        self.titleString = title
        self.content = content
    }
}

struct DiceKeyWithDerivedValue_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template(derivationRecipeTemplates[0]))
//        }
//        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
    }
}
