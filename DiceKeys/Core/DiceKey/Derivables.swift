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

func getDerivationOptionsJson(hosts: [String], sequenceNumber: Int = 1) -> String {
    return "{\"allow\":[\(getHostRestrictionsArrayAsString(hosts))]\(sequenceNumber == 1 ? "" : ",\"#\":\(String(sequenceNumber))" )}"
}

func getDerivationOptionsJson(_ hosts: String..., sequenceNumber: Int = 1) -> String {
    getDerivationOptionsJson(hosts: hosts, sequenceNumber: sequenceNumber)
}

func addSequenceNumberToDerivationOptionsJson(_ derivationOptionsWithoutSequenceNumber: String, sequenceNumber: Int) -> String {
    guard sequenceNumber != 1 else { return derivationOptionsWithoutSequenceNumber }

    guard let lastClosingBraceIndex = derivationOptionsWithoutSequenceNumber.lastIndex(where: { $0 == "}" }) else { return derivationOptionsWithoutSequenceNumber }
    let prefixUpToFinalClosingBrace = derivationOptionsWithoutSequenceNumber.prefix(upTo: lastClosingBraceIndex)
    let suffixIncludingFinalCloseBrace = derivationOptionsWithoutSequenceNumber.suffix(from: lastClosingBraceIndex)

    let commaIfOptionsNonEmpty = derivationOptionsWithoutSequenceNumber.contains(":") ? "," : ""
    let sequenceNumberString = "\(commaIfOptionsNonEmpty)\"#\":\(String(describing: sequenceNumber))"

    return prefixUpToFinalClosingBrace + sequenceNumberString + suffixIncludingFinalCloseBrace
}

protocol DerivationRecipeIdentifiable: Codable, Identifiable {
    var type: DerivationOptionsType { get }
    var name: String { get }
    var derivationOptionsJson: String { get }
}

extension DerivationRecipeIdentifiable {
    var id: String { "\(type):\(name):\(derivationOptionsJson)" }
}

struct DerivationRecipeTemplate: DerivationRecipeIdentifiable, Equatable {
    let type: DerivationOptionsType
    let name: String
    let derivationOptionsJson: String

    init(type: DerivationOptionsType, name: String, derivationOptionsJson: String) {
        self.type = type
        self.name = name
        self.derivationOptionsJson = derivationOptionsJson
    }

    init(type: DerivationOptionsType, name: String, hosts: [String]) {
        self.init(type: type, name: name, derivationOptionsJson: getDerivationOptionsJson(hosts: hosts))
    }

    static func password(_ name: String, _ hosts: String...) -> DerivationRecipeTemplate {
        DerivationRecipeTemplate(type: .Password, name: name, hosts: hosts)
    }
//
//    static func unsealingKey(_ name: String, _ hosts: String...) -> DerivableTemplate {
//        DerivableTemplate(type: .UnsealingKey, name: name, hosts: hosts)
//    }

    static func listFromJson(_ json: String) throws -> [DerivationRecipeTemplate]? {
        return try JSONDecoder().decode([DerivationRecipeTemplate].self, from: json.data(using: .utf8)! )
    }
    static func listToJson(_ derivables: [DerivationRecipeTemplate]) throws -> String { String(decoding: try JSONEncoder().encode(derivables), as: UTF8.self) }
}

struct DerivationRecipe: DerivationRecipeIdentifiable, Equatable {
    let type: DerivationOptionsType
    let name: String
    let derivationOptionsJson: String

    init(type: DerivationOptionsType, name: String, derivationOptionsJson: String) {
        self.type = type
        self.name = name
        self.derivationOptionsJson = derivationOptionsJson
    }

    init(template: DerivationRecipeTemplate, sequenceNumber: Int) {
        self.type = template.type
        self.name = sequenceNumber == 1 ?
            template.name :
            "\(template.name) (\(String(sequenceNumber)))"
        self.derivationOptionsJson =
            addSequenceNumberToDerivationOptionsJson(template.derivationOptionsJson, sequenceNumber: sequenceNumber)
    }

    static func listFromJson(_ json: String) throws -> [DerivationRecipe]? {
        return try JSONDecoder().decode([DerivationRecipe].self, from: json.data(using: .utf8)! )
    }
    static func listToJson(_ derivables: [DerivationRecipe]) throws -> String { String(decoding: try JSONEncoder().encode(derivables), as: UTF8.self) }
 }

let derivationRecipeTemplates: [DerivationRecipeTemplate] = [
    DerivationRecipeTemplate.password("1Password", "1password.com"),
    DerivationRecipeTemplate.password("Apple", "apple.com", "icloud.com"),
    DerivationRecipeTemplate.password("Authy", "authy.com"),
    DerivationRecipeTemplate.password("Bitwarden", "bitwarden.com"),
    DerivationRecipeTemplate.password("Facebook", "facebook.com"),
    DerivationRecipeTemplate.password("Google", "google.com"),
    DerivationRecipeTemplate.password("Keeper", "keepersecurity.com", "keepersecurity.eu"),
    DerivationRecipeTemplate.password("LastPass", "lastpass.com"),
    DerivationRecipeTemplate.password("Microsoft", "microsoft.com", "live.com")
].sorted(by: { $0.id < $1.id })

let derivablePasswordTemplates = derivationRecipeTemplates
    .filter { $0.type == .Password }
