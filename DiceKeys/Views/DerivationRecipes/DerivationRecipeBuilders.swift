//
//  DerivationRecipeBuilders.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/11.
//

import SwiftUI

enum RecipeBuilderProgress: Equatable {
    case incomplete
    case error(String)
    case ready(DerivationRecipe)
    
    var isReady: Bool {
        switch self {
            case .ready: return true
            default: return false
        }
    }
    
    var recipe: DerivationRecipe?{
        switch self {
        case .ready(let derivationRecipe): return derivationRecipe
            default: return nil
        }
    }
}

enum RecipeBuildType {
    case hosts
    case purpose
    case rawJson
}

class RecipeBuilderState: ObservableObject, Identifiable {
    @Published var progress: RecipeBuilderProgress = .incomplete
}

private class DerivationRecipeBuilderForTemplateModel: ObservableObject {
    let template: DerivationRecipe
    var recipeBuilderState: RecipeBuilderState
    @Published var sequenceNumber: Int = 1 { didSet { update() } }

    init(_ template: DerivationRecipe, _ recipeBuilderState: RecipeBuilderState) {
        self.recipeBuilderState = recipeBuilderState
        self.template = template
        update()
    }

    func update() {
        recipeBuilderState.progress = .ready(DerivationRecipe(
            template: template,
            sequenceNumber: sequenceNumber
        ))
    }
}

struct DerivationRecipeBuilderForTemplate: View {
    @ObservedObject private var model: DerivationRecipeBuilderForTemplateModel

    init(recipeBuilderState: RecipeBuilderState, template: DerivationRecipe) {
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

class DerivationRecipeFromUrlModel: ObservableObject, Identifiable {
    @ObservedObject var recipeBuilderState: RecipeBuilderState
    @Published var buildType: RecipeBuildType = .hosts {
        didSet {
            update()
            if(buildType == .rawJson){
                showRawJsonAlert = true
            }
        }
    }
    @Published var urlString: String = "" { didSet { update() } }
    @Published var purposeString: String = "" { didSet { update() } }
    @Published var rawJsonString: String = "{}" { didSet { update() } }
    @Published var nameString: String = "" { didSet { update() } }
    @Published var sequenceNumber: Int = 1 { didSet { update() } }
    @Published var lengthInChars: Int = 0 { didSet { update() } }
    @Published var lengthInBytes: Int = 0 { didSet { update() } }
    
    @Published var showRawJsonAlert: Bool = false { didSet { update() } }
    
    let type: SeededCryptoRecipeType

    var hosts: [String]? {
        if let host = URL(string: urlString)?.host {
            // The field contains a valid URL from which to take a host
            return [host]
        } else if urlString.contains("/") || urlString.contains(":") {
            // The field was an invalid URL and not a list of URLs
            return nil
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
    var name: String {
        if (buildType == .hosts) {
            return hosts?.joined(separator: ", ") ?? ""
        } else if (buildType == .purpose) {
            return purposeString
        }else{
            return nameString
        }
    }

    func update() {
        if(buildType == .hosts){
            guard let hosts = self.hosts else { recipeBuilderState.progress = .error("Field does not contain a valid URL or domain list"); return }
            guard hosts.contains(where: { $0 != "example.com" }) else {
                recipeBuilderState.progress = .incomplete ; return
            }
        } else if(buildType == .purpose) {
            guard !purposeString.isBlank else {
                recipeBuilderState.progress = .incomplete ; return
            }
        }else{
            guard !rawJsonString.isBlank else {
                recipeBuilderState.progress = .incomplete ; return
            }
        }
        
        let recipe : String
        let lengthInChars = type == .Password ? lengthInChars : 0
        let lengthInBytes = type == .Secret ? lengthInBytes : 0
        
        if(buildType == .hosts){
            recipe = getRecipeJson(hosts: hosts ?? [""], sequenceNumber: sequenceNumber, lengthInChars: lengthInChars, lengthInBytes: lengthInBytes)
        } else if(buildType == .purpose){
            recipe = getRecipeJson(purpose: purposeString.trim(), sequenceNumber: sequenceNumber, lengthInChars: lengthInChars, lengthInBytes: lengthInBytes)
        } else {
            recipe = rawJsonString.trim()
        }
        
        self.recipeBuilderState.progress = .ready(DerivationRecipe(
            type: type, name: name,
            recipe: recipe))
    }

    init(_ type: SeededCryptoRecipeType, _ recipeBuilderState: RecipeBuilderState) {
        self.type = type
        self.recipeBuilderState = recipeBuilderState
        update()
    }
}

struct DerivationRecipeForFromUrl: View {
    @ObservedObject private var model: DerivationRecipeFromUrlModel
    
    var lengthInCharsString: Binding<String> {
        return Binding<String>(
            get: {
                if model.lengthInChars == 0 {
                    return ""
                }
                return String(model.lengthInChars)
                
            },
            set: { newValue in
                if (newValue == "") {
                    model.lengthInChars = 0
                }
                if let newIntValue = Int(newValue.filter { "0123456789".contains($0) }) {
                    // We don't value to be greater than 999
                    guard newIntValue <= 999 && newIntValue >= 8 else {
                        return
                    }
                    model.lengthInChars = newIntValue
                }
            }
        )
    }
    
    var lengthInBytesString: Binding<String> {
        return Binding<String>(
            get: {
                if model.lengthInBytes == 0 {
                    return ""
                }
                return String(model.lengthInBytes)
                
            },
            set: { newValue in
                if (newValue == "") {
                    model.lengthInBytes = 0
                }
                if let newIntValue = Int(newValue.filter { "0123456789".contains($0) }) {
                    // We don't value to be greater than 999
                    guard newIntValue <= 999 && newIntValue >= 16 else {
                        return
                    }
                    model.lengthInBytes = newIntValue
                }
            }
        )
    }

    init(type: SeededCryptoRecipeType, recipeBuilderState: RecipeBuilderState) {
        self.model = DerivationRecipeFromUrlModel(type, recipeBuilderState)
    }
    
    init(model: DerivationRecipeFromUrlModel) {
        self.model = model
    }
    
    var urlTextField: some View {
        #if os(iOS)
        return TextField("https://example.com", text: $model.urlString)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .font(.body)
            .multilineTextAlignment(.center)
            .keyboardType(.alphabet)
        #else
        return TextField("https://example.com", text: $model.urlString)
            .disableAutocorrection(true)
            .font(.body)
            .multilineTextAlignment(.center)
        #endif
    }
    
    var purposeTextField: some View {
        #if os(iOS)
        return TextField("purpose", text: $model.purposeString)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .font(.body)
            .multilineTextAlignment(.center)
            .keyboardType(.alphabet)
        #else
        return TextField("purpose", text: $model.purposeString)
            .disableAutocorrection(true)
            .font(.body)
            .multilineTextAlignment(.center)
        #endif
    }
    
    var nameTextField: some View {
        #if os(iOS)
        return TextField("Recipe name", text: $model.nameString)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .font(.body)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .keyboardType(.alphabet)
        #else
        return TextField("Recipe name", text: $model.nameString)
            .disableAutocorrection(true)
            .font(.body)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
        #endif
    }
    
    var rawJsonTextField: some View {
        #if os(iOS)
        return TextField("Raw JSON", text: $model.rawJsonString)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .font(.body)
            .lineLimit(4)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .keyboardType(.alphabet)
        #else
        return TextField("Raw JSON", text: $model.rawJsonString)
            .disableAutocorrection(true)
            .font(.body)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
        #endif
    }
    
    var lengthInCharsTextfield: some View {
        TextField("no length limit", text: lengthInCharsString)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.top, 10)
#if os(iOS)
            .keyboardType(.numberPad)
#endif
    }
    
    var lengthInBytesTextfield: some View {
        TextField("32", text: lengthInBytesString)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.top, 10)
#if os(iOS)
            .keyboardType(.numberPad)
#endif
    }

    var body: some View {
        
        HStack(alignment: .top, spacing: 0){
            VStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("What is this recipe for?")
                        .font(.caption)
                    Picker("", selection: $model.buildType ) {
                        Text("Web Address").tag(RecipeBuildType.hosts)
                        Text("Purpose").tag(RecipeBuildType.purpose)
                        Text("Raw JSON").tag(RecipeBuildType.rawJson)
                    }.pickerStyle(.segmented)
                    .padding(.top, 4)
                    .alert(isPresented:  $model.showRawJsonAlert) {
        
                        Alert(
                            title: Text("Edit Raw JSON"),
                            message: Text("Entering a recipe in raw JSON format can be dangerous.\n\nIf you enter a recipe provided by someone else, it could be a trick to get you to re-create a secret you use for another application or purpose.\n\nIf you generate the recipe yourself and forget even a single character, you will be unable to re-generate the same secret again. (Saving the recipe won't help you if you lose the device(s) it's saved on.)"),
                            primaryButton: .default(
                                Text("I accept the risk"),
                                action: {
                                    model.showRawJsonAlert = false
                                }
                            ),
                            secondaryButton: .destructive(
                                Text("Cancel"),
                                action: {
                                    model.showRawJsonAlert = false
                                    model.buildType = .hosts
                                }
                            )
                            
                        )
                    }
                    
                    if(model.buildType == .hosts){
                        urlTextField
                            .padding(.top, 10)
                    }else if(model.buildType == .purpose){
                        purposeTextField
                            .padding(.top, 10)
                    }else{
                        nameTextField
                            .padding(.top, 10)
                        rawJsonTextField
                            .padding(.top, 10)
                    }
                    
                    Text((model.buildType == .rawJson ? "Even the smallest change to any field changes the entire " : model.buildType == .hosts ? "Paste or enter the address of the website that will use this " : "Enter a purpose for the ") + self.model.type.descriptionForRecipeBuilder)
                        .font(.footnote)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.gray)
                    
                    
                    if case let RecipeBuilderProgress.error(errorString) = model.recipeBuilderState.progress {
                        Text(errorString).font(.footnote).foregroundColor(.red)
                    }
                    
                    if(model.buildType != .rawJson){
                        if model.type == .Password{
                            lengthInCharsTextfield
                            Text("Maximum length, in characters (8 - 999)").font(.footnote).foregroundColor(.gray)
                        }else if model.type == .Secret{
                            lengthInBytesTextfield
                            Text("Length, in bytes (16 - 999)").font(.footnote).foregroundColor(.gray)
                        }
                    }
                }
                if(model.buildType != .rawJson){
                    SequenceNumberField(sequenceNumber: $model.sequenceNumber)
                        .padding(.top, 10)
                }
            }
        }
        .padding()
    }
}

private class DerivationRecipeForFromRecipeJsonModel: ObservableObject {
    @ObservedObject var recipeBuilderState: RecipeBuilderState
    @Published var type: SeededCryptoRecipeType = .Password { didSet { update() } }
    @Published var name: String = "My custom derivation options" { didSet { update() } }
    @Published var recipe: String = "" { didSet { update() } }

    func update() {
        self.recipeBuilderState.progress = .ready(DerivationRecipe(
            type: type, name: name, recipe: recipe
        ))
    }

    init(_ recipeBuilderState: RecipeBuilderState) {
        self.recipeBuilderState = recipeBuilderState
        update()
    }
}

struct DerivationRecipeForFromRecipeJson: View {
    @ObservedObject private var model: DerivationRecipeForFromRecipeJsonModel

    init(recipeBuilderState: RecipeBuilderState) {
        self.model = DerivationRecipeForFromRecipeJsonModel(recipeBuilderState)
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
//        case .custom: DerivationRecipeForFromRecipeJson(recipeBuilderState: recipeBuilderState)
        case .recipe: EmptyView()
        }
    }
}

struct DerivationRecipeView: View {
    let recipeBuilderProgress: RecipeBuilderProgress
    
    var body: some View {
        VStack {
            switch (recipeBuilderProgress) {
            case .incomplete:
                Text("Complete the recipe above to see the output")
                    .font(Font.system(.footnote, design: .monospaced))
                    .foregroundColor(.gray)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
            case .error(let errorString):
                Text(errorString)
                    .font(Font.system(.footnote, design: .monospaced))
                    .foregroundColor(.red)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
            case .ready(let recipe):
                if let recipeJson = recipe.recipe {
                    Text(recipeJson)
                        .font(Font.system(.footnote, design: .monospaced))
                        .scaledToFit()
                        .minimumScaleFactor(0.01)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct DerivationRecipeBuilders_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        DerivationRecipeForFromUrl(type: .Password, recipeBuilderState: RecipeBuilderState())
        .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        .environmentObject(DerivationRecipeStore())
        
        DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .customFromUrl(.Password))
        .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        .environmentObject(DerivationRecipeStore())
//        .environment(\.colorScheme, .dark)

        DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
        .environmentObject(DerivationRecipeStore())
        .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        .environment(\.colorScheme, .dark)

//        NavigationView {
//            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .template( derivationRecipeTemplates[0]))
//        }
//        .navigationViewStyle(StackNavigationViewStyle())
//        .navigationBarDiceKeyStyle()
//        .previewDevice(PreviewDevice(rawValue: "iPad Air (4th generation)"))
//        .environment(\.colorScheme, .dark)
        #else
            DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom(), derivationRecipeBuilder: .customFromUrl(.Password))
        #endif
    }
}
