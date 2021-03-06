//
//  Derivables.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import Foundation
import SeededCrypto

func getHostRestrictionsArrayAsString(_ hosts: [String]) -> String {
    return "[" + (
        hosts
            .map { host in "{\"host\":\"*.\(host)\"}" }
            .joined(separator: ",")
        ) +
        "]"
}

func restrictionsJson(_ hosts: String...) -> String {
    return "{\"allow\":\(getHostRestrictionsArrayAsString(hosts))}"
}

func getRecipeJson(hosts: [String], sequenceNumber: Int = 1, lengthInChars: Int = -1) -> String {
    let sortedHosts = hosts.sorted()
    return """
{"allow":\(getHostRestrictionsArrayAsString(sortedHosts))\(
    (lengthInChars <= 0 ? "" : ",\"lengthInChars\":\(String(lengthInChars))") +
    (sequenceNumber == 1 ? "" : ",\"#\":\(String(sequenceNumber))")
)}
"""
}

func getRecipeJson(_ hosts: String..., sequenceNumber: Int = 1) -> String {
    getRecipeJson(hosts: hosts, sequenceNumber: sequenceNumber)
}

func addFieldToEndOfJsonObjectString(_ originalJsonObjectString: String, fieldName: String, fieldValue: String) -> String {
    guard let lastClosingBraceIndex = originalJsonObjectString.lastIndex(where: { $0 == "}" }) else { return originalJsonObjectString }
    let prefixUpToFinalClosingBrace = originalJsonObjectString.prefix(upTo: lastClosingBraceIndex)
    let suffixIncludingFinalCloseBrace = originalJsonObjectString.suffix(from: lastClosingBraceIndex)
    let commaIfObjectNonEmpty = originalJsonObjectString.contains(":") ? "," : ""
    return String(prefixUpToFinalClosingBrace) + "\(commaIfObjectNonEmpty)\"\(fieldName)\":\(fieldValue)" + suffixIncludingFinalCloseBrace
}

func addLengthInCharsToRecipeJson(_ recipeWithoutLengthInChars: String, lengthInChars: Int = 0 ) -> String {
    guard lengthInChars > 0 else { return recipeWithoutLengthInChars }
    return addFieldToEndOfJsonObjectString(recipeWithoutLengthInChars, fieldName: "lengthInChars", fieldValue: String(describing: lengthInChars))
}

func addSequenceNumberToRecipeJson(_ recipeWithoutSequenceNumber: String, sequenceNumber: Int) -> String {
    guard sequenceNumber != 1 else { return recipeWithoutSequenceNumber }
    return addFieldToEndOfJsonObjectString(recipeWithoutSequenceNumber, fieldName: "#", fieldValue: String(describing: sequenceNumber))
}


struct DerivationRecipe: Identifiable, Codable, Equatable {
    let type: SeededCryptoRecipeType
    let name: String
    let recipe: String
    
    var id: String { "\(type):\(name):\(recipe)" }

    init(type: SeededCryptoRecipeType, name: String, recipe: String) {
        self.type = type
        self.name = name
        self.recipe = recipe
    }

    init(template: DerivationRecipe, sequenceNumber: Int, lengthInChars: Int = 0) {
        self.type = template.type
        let typeSuffix = template.type == .Password ? " Password" : template.type == .SymmetricKey ? " Key" : template.type == .UnsealingKey ? " Key Pair" : ""
        let sequenceSuffix = sequenceNumber == 1 ? "" : " (\(String(sequenceNumber)))"
        self.name = template.name + typeSuffix + sequenceSuffix
        var recipe = template.recipe
        if (template.type == .Password && lengthInChars > 0) {
            recipe = addLengthInCharsToRecipeJson(recipe, lengthInChars: lengthInChars)
        }
        recipe =
            addSequenceNumberToRecipeJson(recipe, sequenceNumber: sequenceNumber)
        self.recipe = recipe
    }

    static func listFromJson(_ json: String) throws -> [DerivationRecipe]? {
        return try JSONDecoder().decode([DerivationRecipe].self, from: json.data(using: .utf8)! )
    }
    static func listToJson(_ derivables: [DerivationRecipe]) throws -> String { String(decoding: try JSONEncoder().encode(derivables), as: UTF8.self) }
}

let derivablePasswordTemplates = derivationRecipeTemplates
    .filter { $0.type == .Password }
