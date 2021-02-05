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

func getDerivationOptionsJson(hosts: [String], sequenceNumber: Int = 1, lengthInChars: Int = -1) -> String {
    let sortedHosts = hosts.sorted()
    return """
{"allow":\(getHostRestrictionsArrayAsString(sortedHosts))\(
    (lengthInChars <= 0 ? "" : ",\"lengthInChars\":\(String(lengthInChars))") +
    (sequenceNumber == 1 ? "" : ",\"#\":\(String(sequenceNumber))")
)}
"""
}

func getDerivationOptionsJson(_ hosts: String..., sequenceNumber: Int = 1) -> String {
    getDerivationOptionsJson(hosts: hosts, sequenceNumber: sequenceNumber)
}

func addFieldToEndOfJsonObjectString(_ originalJsonObjectString: String, fieldName: String, fieldValue: String) -> String {
    guard let lastClosingBraceIndex = originalJsonObjectString.lastIndex(where: { $0 == "}" }) else { return originalJsonObjectString }
    let prefixUpToFinalClosingBrace = originalJsonObjectString.prefix(upTo: lastClosingBraceIndex)
    let suffixIncludingFinalCloseBrace = originalJsonObjectString.suffix(from: lastClosingBraceIndex)
    let commaIfObjectNonEmpty = originalJsonObjectString.contains(":") ? "," : ""
    return String(prefixUpToFinalClosingBrace) + "\(commaIfObjectNonEmpty)\"\(fieldName)\":\(fieldValue)" + suffixIncludingFinalCloseBrace
}

func addLengthInCharsToDerivationOptionsJson(_ derivationOptionsWithoutLengthInChars: String, lengthInChars: Int = 0 ) -> String {
    guard lengthInChars > 0 else { return derivationOptionsWithoutLengthInChars }
    return addFieldToEndOfJsonObjectString(derivationOptionsWithoutLengthInChars, fieldName: "lengthInChars", fieldValue: String(describing: lengthInChars))
}

func addSequenceNumberToDerivationOptionsJson(_ derivationOptionsWithoutSequenceNumber: String, sequenceNumber: Int) -> String {
    guard sequenceNumber != 1 else { return derivationOptionsWithoutSequenceNumber }
    return addFieldToEndOfJsonObjectString(derivationOptionsWithoutSequenceNumber, fieldName: "#", fieldValue: String(describing: sequenceNumber))
}


struct DerivationRecipe: Identifiable, Codable, Equatable {
    let type: DerivationOptionsType
    let name: String
    let derivationOptionsJson: String
    
    var id: String { "\(type):\(name):\(derivationOptionsJson)" }

    init(type: DerivationOptionsType, name: String, derivationOptionsJson: String) {
        self.type = type
        self.name = name
        self.derivationOptionsJson = derivationOptionsJson
    }

    init(template: DerivationRecipe, sequenceNumber: Int, lengthInChars: Int = 0) {
        self.type = template.type
        let typeSuffix = template.type == .Password ? " Password" : template.type == .SymmetricKey ? " Key" : template.type == .UnsealingKey ? " Key Pair" : ""
        let sequenceSuffix = sequenceNumber == 1 ? "" : " (\(String(sequenceNumber)))"
        self.name = template.name + typeSuffix + sequenceSuffix
        var derivationOptionsJson = template.derivationOptionsJson
        if (template.type == .Password && lengthInChars > 0) {
            derivationOptionsJson = addLengthInCharsToDerivationOptionsJson(derivationOptionsJson, lengthInChars: lengthInChars)
        }
        derivationOptionsJson =
            addSequenceNumberToDerivationOptionsJson(derivationOptionsJson, sequenceNumber: sequenceNumber)
        self.derivationOptionsJson = derivationOptionsJson
    }

    static func listFromJson(_ json: String) throws -> [DerivationRecipe]? {
        return try JSONDecoder().decode([DerivationRecipe].self, from: json.data(using: .utf8)! )
    }
    static func listToJson(_ derivables: [DerivationRecipe]) throws -> String { String(decoding: try JSONEncoder().encode(derivables), as: UTF8.self) }
}

let derivablePasswordTemplates = derivationRecipeTemplates
    .filter { $0.type == .Password }
