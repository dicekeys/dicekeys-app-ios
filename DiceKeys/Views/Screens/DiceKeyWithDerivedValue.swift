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

    @EnvironmentObject private var recipeStore: DerivationRecipeStore
    @State var view : DerivedValueView = .JSON
    @StateObject var recipeBuilderState = RecipeBuilderState()

    var diceKeyState: UnlockedDiceKeyState {
        UnlockedDiceKeyState.forDiceKey(diceKey)
    }

    var derivationRecipe: DerivationRecipe? {
        // This is a complete final recipe
        if case let .recipe(recipe) = derivationRecipeBuilder {
            return recipe
        }
        // This is a template for building recipes
        guard case let .ready(derivationRecipe) = recipeBuilderState.progress else { return nil }
            return derivationRecipe
    }
    
    var derivedValue: DerivedValue?{
        return derivationRecipe?.derivedValue(diceKey: diceKey)
    }

    var recipe: String? {
        derivationRecipe?.recipe
    }

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

    var body: some View {
        return VStack(alignment: .center, spacing: 0) {
           if let derivationRecipeBuilder = self.derivationRecipeBuilder {
                FormCard(title: "Recipe\( derivationRecipe == nil ? "" : " for \( derivationRecipe?.name ?? "" )")") {
                    VStack(alignment: .leading) {
                        if derivationRecipeBuilder.isBuilder {
                            DerivationRecipeBuilder(derivableMenuChoice: derivationRecipeBuilder, recipeBuilderState: recipeBuilderState)
                        }
                        Divider().hideIf(derivationRecipe == nil)
                        Text("Internal representation of your recipe").hideIf(derivationRecipe == nil)
                            //.font(.title2)
                            .scaledToFit()
                            .minimumScaleFactor(0.01)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(1)
                        DerivationRecipeView(recipeBuilderProgress:
                            self.derivationRecipeBuilder.isRecipe ?
                                .ready(self.derivationRecipe!) :
                                self.recipeBuilderState.progress
                        ).padding(.top, 3)
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
               if let derivedValue = derivedValue {
                   HStack{
                       Text("Output Format:")
                       Picker("", selection: $view) {
                           ForEach(derivedValue.views) { view in
                               Text(view.description).tag(view)
                           }
                       }.pickerStyle(.menu)
                       Spacer()
                   }
                   .padding(.leading, 10)
                   .padding(.trailing, 10)
               
               }
                VStack(alignment: .center, spacing: 0) {
                    DerivedFromDiceKey(diceKey: diceKeyState.diceKey, content: {
                        Text(derivedValue?.valueForView(view: view) ?? "")
                                .padding(3)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .lineLimit(5)
                                .minimumScaleFactor(0.4)
                                .fixedSize(horizontal: false, vertical: true)
//                                .padding(.horizontal, 5)
                    }).padding(.horizontal, 5).layoutPriority(-1)
                    if let derivedValue = derivedValue , let value = derivedValue.valueForView(view: view), value != "" {
                        Button("Copy \( view.description )") {
                            #if os(iOS)
                            UIPasteboard.general.string = value
                            #else
                            let pasteboard = NSPasteboard.general
                            pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                            pasteboard.setString(value, forType: .string)
                            #endif
                        }
                    }
                }.hideIf(derivationRecipe == nil)
            }
        }.onAppear() {
            
            self.view = derivedValue?.views.first ?? .JSON
            
            if let derivationRecipe = derivationRecipe, let firstView = derivationRecipe.derivedValue(diceKey: diceKey).views.first{
                if let purpose = derivationRecipe.purpose(){
                    if(purpose == "pgp" && derivationRecipe.type == .SigningKey){
                        self.view = .OpenPGPPrivateKey
                    }else if(purpose == "ssh" && derivationRecipe.type == .SigningKey){
                        self.view = .OpenSSHPrivateKey
                    }
                }
                
            }
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
                        .font(.headline)
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
    static let derivationRecipeStore = DerivationRecipeStore()
    static var previews: some View {
//        NavigationView {
        Group {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(),
                                        derivationRecipeBuilder: .template(derivationRecipeTemplates[0]))
            .environmentObject(derivationRecipeStore)
            .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
            
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(),
                                    derivationRecipeBuilder: .template(derivationRecipeTemplates[10]))
            .environmentObject(derivationRecipeStore)
            
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(),
                                    derivationRecipeBuilder: .customFromUrl(.Password))
            .environmentObject(derivationRecipeStore)
        }
    }
}
