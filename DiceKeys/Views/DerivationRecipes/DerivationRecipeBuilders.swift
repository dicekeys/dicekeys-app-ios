//
//  DerivationRecipeBuilders.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/11.
//

import SwiftUI


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
            SequenceNumberField(sequenceNumber: $model.sequenceNumber)
        }
    }
}

private class DerivationRecipeForFromUrlModel: ObservableObject {
    @ObservedObject var recipeBuilderState: RecipeBuilderState
    @Published var urlString: String = "https://example.com" { didSet { update() } }
    @Published var sequenceNumber: Int = 1 { didSet { update() } }
    let type: DerivationOptionsType

    var hosts: [String] {
        if let host = URL(string: urlString)?.host, host != "example.com" {
            // The field contains a valid URL from which to take a host
            return [host]
        } else if urlString.contains("/") || urlString.contains(":") {
            // The field was an invalid URL and not a list of URLs
            return []
        } else {
            // Assume the field was meant to be a URL or list of URLs
            return urlString
                .split(whereSeparator: {$0 == "/" || $0 == " " })
                .map {
                    // Use built-in URL parser to parse domain name, returning empty string if it fails
                    URL(string: "https://\( $0.trimmingCharacters(in: .whitespacesAndNewlines) )")?.host ?? ""
                }
                .filter {
                    // filter out the empty strings
                    $0.count > 0
                }
        }
    }
    var name: String { hosts.joined(separator: ", ") }

    func update() {
        guard hosts.count > 0 else { recipeBuilderState.derivationRecipe = nil; return }
        self.recipeBuilderState.derivationRecipe = DerivationRecipe(
            type: type, name: name,
            derivationOptionsJson: getDerivationOptionsJson(hosts: hosts, sequenceNumber: sequenceNumber))
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
    
    var textfield: some View {
        TextField("URL or comma-separated list of domains", text: $model.urlString)
            .font(.body)
            .multilineTextAlignment(.center)
    }

    var body: some View {
        return VStack {
            VStack(alignment: .center, spacing: 0) {
                #if os(iOS)
                textfield.keyboardType(.numberPad)
                #else
                textfield
                #endif
                Text("URL or comma-separated list of domains").font(.footnote).foregroundColor(.gray)
            }
            SequenceNumberField(sequenceNumber: $model.sequenceNumber)
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
//        case .custom: DerivationRecipeForFromDerivationOptionsJson(recipeBuilderState: recipeBuilderState)
        case .recipe: EmptyView()
        }
    }
}

struct DerivationRecipeView: View {
    let recipe: DerivationRecipe?

    var body: some View {
        VStack {
            Text(recipe?.derivationOptionsJson ?? "{}")
                .font(Font.system(.footnote, design: .monospaced))
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(1)
        }
    }
}

struct DerivationRecipeBuilders_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .customFromUrl(.Password))
        }
        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        .environment(\.colorScheme, .dark)

        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        }
        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        .environment(\.colorScheme, .dark)

        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarDiceKeyStyle()
        .previewDevice(PreviewDevice(rawValue: "iPad Air (4th generation)"))
        .environment(\.colorScheme, .dark)
        #else
        NavigationView {
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .customFromUrl(.Password))
        }
        #endif
    }
}
