//
//  SecretsView.swift
//  DiceKeys
//
//  Created by Angelos Veglektsis on 7/6/22.
//

import SwiftUI

class SecretsViewModel: ObservableObject, Identifiable {
    @Published var recipeBuilderState: RecipeBuilderState? = nil
    @Published var derivationRecipeModel: DerivationRecipeFromUrlModel? = nil
}

struct SecretsView: View {
    @EnvironmentObject var derivationRecipeStore: DerivationRecipeStore
    
    let navigateTo: (DiceKeyPresentPageContent) -> Void
    
    @StateObject var model = SecretsViewModel()

    var body: some View {
        
        return List{
            if(derivationRecipeStore.savedDerivationRecipes.count > 0){
                Section(header: Text("Saved Recipes")) {
                    ForEach(derivationRecipeStore.savedDerivationRecipes) { recipe in
                        HStack{
                            Text(recipe.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture(perform: {
                            navigateTo(.Derive(DerivationRecipeBuilderType.recipe(recipe)))
                        })
                    }
                }
            }

            Section(header: Text("Built-in Recipes")) {
                ForEach(derivableTemplates) { template in
                    HStack{
                        Text(template.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: {
                        navigateTo(.Derive(DerivationRecipeBuilderType.template(template)))
                    })
                }
            }
            
            Section(header: Text("Custom Recipe")) {
                ForEach(SeededCryptoRecipeType.allCases) { type in
                    HStack{
                        Text(type.description)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture(perform: {
                        model.recipeBuilderState = RecipeBuilderState()
                        
                        if let recipeBuilderState = model.recipeBuilderState{
                            model.derivationRecipeModel = DerivationRecipeFromUrlModel(type, recipeBuilderState)
                        }
                    })
                }
            }
            .sheet(item: $model.derivationRecipeModel ) { item in
                VStack(alignment: .leading, spacing: 0) {

                    HStack{
                        Button("Cancel"){
                             model.derivationRecipeModel = nil
                        }
                        
                        Spacer()
                        Text(item.type.descriptionForRecipeBuilder.capitalized)
                            .bold()
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            
                        Spacer()
                        Button("Done"){
                            
                            if let recipe = model.recipeBuilderState?.progress.recipe {
                                navigateTo(.Derive(DerivationRecipeBuilderType.recipe(recipe)))
                            }
                            model.derivationRecipeModel = nil
                        }
                        
                    }.padding()
                    
                    if let derivationRecipeModel = model.derivationRecipeModel {
                        DerivationRecipeForFromUrl(model: derivationRecipeModel)
                    }
                    
                    Spacer()
                }
                
            }
        }
    }
}

struct SecretsView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            SecretsView(navigateTo: { _ in
                
            })
            .environmentObject(DerivationRecipeStore())
        }
    }
}
