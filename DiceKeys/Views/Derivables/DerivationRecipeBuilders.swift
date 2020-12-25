//
//  DerivationRecipeBuilders.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/11.
//

import SwiftUI

struct SequenceNumberView: View {
    @Binding var sequenceNumber: Int

    var sequenceNumberString: Binding<String> {
        return Binding<String>(
            get: { String(sequenceNumber) },
            set: { newValue in
                if let newIntValue = Int(newValue.filter { "0123456789".contains($0) }) {
                    sequenceNumber = newIntValue
                }
            }
        )
    }

    var body: some View {
        HStack {
            #if os(iOS)
            TextField("Sequence Number", text: sequenceNumberString)
                .font(.title)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center).frame(maxWidth: 40).padding(.leading, 10)
            #else
            TextField("Sequence Number", text: sequenceNumberString)
                .font(.title)
                .multilineTextAlignment(.center).frame(maxWidth: 40).padding(.leading, 10)
            #endif
            VStack {
                Button(action: { sequenceNumber += 1 },
                    label: {
                        Image(systemName: "arrow.up.square")
    //                                .scaleEffect(2)
    //                                .aspectRatio(contentMode: .fit)
                    }
                ).buttonStyle(PlainButtonStyle())
                Button(action: { sequenceNumber = max(1, sequenceNumber - 1) },
                    label: {
                        Image(systemName: "arrow.down.square")
    //                                .resizable()
    //                                .aspectRatio(contentMode: .fit)
                    }
                ).buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct FieldCard<Content: View>: View {
    let label: String
    let field: () -> Content

    init(_ label: String, @ViewBuilder field: @escaping () -> Content) {
        self.label = label
        self.field = field
    }

    var body: some View {
        VStack(alignment: .center) {
            field()
            Text(label).font(.footnote)
        }
    }
}

//private struct RecipePassiveEmptyView: View {
//    init(derivationRecipe: Binding<DerivationRecipe?>, recipe: DerivationRecipe) {
//        derivationRecipe.wrappedValue = recipe
//    }
//
//    var body: some View { EmptyView() }
//}

class RecipeBuilderState: ObservableObject {
    @Published var derivationRecipe: DerivationRecipe?
    init() {}
}

private class DerivationRecipeBuilderForTemplateModel: ObservableObject {
    let template: DerivationRecipeTemplate
     var recipeBuilderState: RecipeBuilderState
    @Published var sequenceNumber: Int = 1 { didSet { update() } }

    init(_ template: DerivationRecipeTemplate, _ recipeBuilderState: RecipeBuilderState) {
        self.recipeBuilderState = recipeBuilderState
        self.template = template
        update()
    }

    func update() {
        recipeBuilderState.derivationRecipe = DerivationRecipe(
            template: template,
            sequenceNumber: sequenceNumber
        )
    }
}

struct DerivationRecipeBuilderForTemplate: View {
    @ObservedObject private var model: DerivationRecipeBuilderForTemplateModel

    init(recipeBuilderState: RecipeBuilderState, template: DerivationRecipeTemplate) {
        self.model = DerivationRecipeBuilderForTemplateModel(template, recipeBuilderState)
    }

    var body: some View {
        // This app will remember that you've created a password for
        // X before, but you'll need to add this option if you use
        // the DiceKeys app on another device
        VStack {
            Text("If you need more than one password for the same service, change the sequence number.").multilineTextAlignment(.leading)
            FieldCard("Sequence Number") { SequenceNumberView(sequenceNumber: $model.sequenceNumber) }
        }
    }
}

private class DerivationRecipeForFromUrlModel: ObservableObject {
    @ObservedObject var recipeBuilderState: RecipeBuilderState
    @Published var urlString: String = "" { didSet { update() } }
    @Published var sequenceNumber: Int = 1 { didSet { update() } }
    let type: DerivationOptionsType

    var host: String? { URL(string: urlString)?.host }
    var name: String { host ?? "" }

    func update() {
        guard let host = host else { recipeBuilderState.derivationRecipe = nil; return }
        self.recipeBuilderState.derivationRecipe = DerivationRecipe(
            type: type, name: name,
            derivationOptionsJson: getDerivationOptionsJson(host, sequenceNumber: sequenceNumber))
    }

    init(_ type: DerivationOptionsType, _ recipeBuilderState: RecipeBuilderState) {
        self.type = type
        self.recipeBuilderState = recipeBuilderState
        update()
    }
}

struct DerivationRecipeForFromUrl: View {
    @ObservedObject private var model: DerivationRecipeForFromUrlModel

    init(type: DerivationOptionsType, recipeBuilderState: RecipeBuilderState) {
        self.model = DerivationRecipeForFromUrlModel(type, recipeBuilderState)
    }

    var body: some View {
        VStack {
            Text("FIXME")
        }
    }
}

private class DerivationRecipeForFromDerivationOptionsJsonModel: ObservableObject {
    @ObservedObject var recipeBuilderState: RecipeBuilderState
    @Published var type: DerivationOptionsType = .Password { didSet { update() } }
    @Published var name: String = "My custom derivation options" { didSet { update() } }
    @Published var derivationOptionsJson: String = "" { didSet { update() } }

    func update() {
        self.recipeBuilderState.derivationRecipe = DerivationRecipe(
            type: type, name: name, derivationOptionsJson: derivationOptionsJson
        )
    }

    init(_ recipeBuilderState: RecipeBuilderState) {
        self.recipeBuilderState = recipeBuilderState
        update()
    }
}

struct DerivationRecipeForFromDerivationOptionsJson: View {
    @ObservedObject private var model: DerivationRecipeForFromDerivationOptionsJsonModel

    init(recipeBuilderState: RecipeBuilderState) {
        self.model = DerivationRecipeForFromDerivationOptionsJsonModel(recipeBuilderState)
    }
    var body: some View {
        VStack {
            Text("FIXME")
        }
    }
}

struct DerivationRecipeBuilder: View {
    let derivableMenuChoice: DerivationRecipeBuilderType
    let recipeBuilderState: RecipeBuilderState
//    @Binding var derivationRecipe: DerivationRecipe?

    var body: some View {
        switch derivableMenuChoice {
        case .template(let template): DerivationRecipeBuilderForTemplate(recipeBuilderState: recipeBuilderState, template: template)
        case .customFromUrl(let secretType): DerivationRecipeForFromUrl(type: secretType, recipeBuilderState: recipeBuilderState)
        case .custom: DerivationRecipeForFromDerivationOptionsJson(recipeBuilderState: recipeBuilderState)
//        case .none: EmptyView()
        default: EmptyView()
        }
    }
}

struct DerivationRecipeView: View {
    let recipe: DerivationRecipe

    var body: some View {
        VStack {
            Text(recipe.derivationOptionsJson)
                .font(.footnote)
                .minimumScaleFactor(0.01)
                .scaledToFit()
                .lineLimit(1)
        }
    }
}

//struct DerivationRecipeBuilders: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
struct DerivationRecipeBuilders_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        }
        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPad Air (4th generation)"))
        #else
        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        }
        #endif
    }
}
