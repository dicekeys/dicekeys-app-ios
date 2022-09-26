//
//  Derivables.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import Foundation
import SeededCrypto

func getRecipeJson(hosts: [String], sequenceNumber: Int = 1, lengthInChars: Int = -1, lengthInBytes: Int = -1) -> String {
    var recipe = Dictionary<String, Any>()
    
    recipe["allow"] = hosts.sorted()
    recipe.addSequenceNumberToDerivationOptionsJson(sequenceNumber)
    recipe.addLengthInCharsToDerivationOptionsJson(lengthInChars)
    recipe.addLengthInBytesToDerivationOptionsJson(lengthInBytes)

    return recipe.canonicalize()
}

func getRecipeJson(purpose: String, sequenceNumber: Int = 1, lengthInChars: Int = -1, lengthInBytes: Int = -1) -> String {
    var recipe = Dictionary<String, Any>()
    
    recipe["purpose"] = purpose
    recipe.addSequenceNumberToDerivationOptionsJson(sequenceNumber)
    recipe.addLengthInCharsToDerivationOptionsJson(lengthInChars)
    recipe.addLengthInBytesToDerivationOptionsJson(lengthInBytes)
    
    return recipe.canonicalize()
}

func getRecipeJson(_ hosts: String..., sequenceNumber: Int = 1) -> String {
    getRecipeJson(hosts: hosts, sequenceNumber: sequenceNumber)
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func rebuild(updateJsonObject: Dictionary<String,Any>, skipProperties: [String]) -> Dictionary<String, Any> {
        var dict = Dictionary<String, Any>()
        
        let keys = self.keys.filter { key in
            return !skipProperties.contains(key as! String)
        }
        
        keys.forEach { key in
            dict[key as! String] = self[key]
        }
        
        updateJsonObject.forEach { (key: String, value: Any) in
            dict[key] = value
        }
        
        return dict
    }
    
    
    func canonicalize() -> String{
        return toCanonicalizeRecipeJson(self)
    }
    
    mutating func addLengthInCharsToDerivationOptionsJson(_ lengthInChars: Int?){
        if let lengthInChars = lengthInChars, lengthInChars > 1{
            self["lengthInChars"] = lengthInChars as? Value
        }
    }
    
    mutating func addLengthInBytesToDerivationOptionsJson(_ lengthInBytes: Int?){
        if let lengthInBytes = lengthInBytes, lengthInBytes > 1{
            self["lengthInBytes"] = lengthInBytes as? Value
        }
    }
    
    mutating func addSequenceNumberToDerivationOptionsJson(_ sequenceNumber: Int){
        if(sequenceNumber > 1){
            self["#"] = sequenceNumber as? Value
        }
    }
}

extension Dictionary {
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
    }
    
    func toJSONString() -> String? {
        if let jsonData = jsonData {
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        }
        
        return nil
    }
}

extension String{
    
    func parseJsonObject() -> Dictionary<String, Any>? {
        if let data = self.data(using: .utf8){
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                return json
            }
        }
        return nil
    }
    
    func canonicalizeRecipeJson() -> String {
        return parseJsonObject()?.canonicalize() ?? self
    }
    
    func recipeWith(sequence: Int?) -> String {
        if let sequence = sequence, var json = self.parseJsonObject(){
            json.addSequenceNumberToDerivationOptionsJson(sequence)
            return json.canonicalize()
        }
        
        return self
    }
}

struct DerivationRecipe: Identifiable, Codable, Equatable {
    
    static let rebuildSkipJsonProperties = ["#", "lengthInChars", "lengthInBytes"]
    
    let type: SeededCryptoRecipeType
    let name: String
    let recipe: String
    
    var id: String { "\(type):\(name):\(recipe)" }

    init(type: SeededCryptoRecipeType, name: String, recipe: String) {
        self.type = type
        self.name = name
        self.recipe = recipe
    }

    init(template: DerivationRecipe, sequenceNumber: Int, lengthInChars: Int? = nil, lengthInBytes: Int? = nil) {
        self.type = template.type
        let typeSuffix = template.type == .Password ? " Password" : template.type == .SymmetricKey ? " Key" : template.type == .UnsealingKey ? " Key Pair" : ""
        let sequenceSuffix = sequenceNumber == 1 ? "" : " (\(String(sequenceNumber)))"
        self.name = template.name + typeSuffix + sequenceSuffix

        
        var updateJsonObject = Dictionary<String, Any>()
        
        updateJsonObject.addSequenceNumberToDerivationOptionsJson(sequenceNumber)
        
        if (template.type == .Password){
            updateJsonObject.addLengthInCharsToDerivationOptionsJson(lengthInChars)
        }else if (template.type == .Secret){
            updateJsonObject.addLengthInBytesToDerivationOptionsJson(lengthInBytes)
        }
        
        self.recipe = template.recipe.parseJsonObject()!.rebuild(updateJsonObject: updateJsonObject, skipProperties: DerivationRecipe.rebuildSkipJsonProperties).canonicalize()
    }

    static func listFromJson(_ json: String) throws -> [DerivationRecipe]? {
        return try JSONDecoder().decode([DerivationRecipe].self, from: json.data(using: .utf8)! )
    }
    
    static func listToJson(_ derivables: [DerivationRecipe]) throws -> String { String(decoding: try JSONEncoder().encode(derivables), as: UTF8.self) }
}

extension DerivationRecipe{
    
    func derivedValue(diceKey: DiceKey) -> DerivedValue{
        
        let seed = diceKey.toSeed()
        let recipe = self.recipe
        
        switch self.type{
            case .Password:
                return DerivedValuePassword(password: try! Password.deriveFromSeed(withSeedString: seed, recipe: recipe))
            case .Secret:
                let lengthInBytes = self.lengthInBytes()
                return DerivedValueSecret(secret: try! Secret.deriveFromSeed(withSeedString: seed, recipe: recipe), showBIP39: (lengthInBytes == nil || lengthInBytes == 32))
            case .SigningKey:
                return DerivedValueSigningKey(signingKey: try! SigningKey.deriveFromSeed(withSeedString: seed, recipe: recipe))
            case .SymmetricKey:
                return DerivedValueSymmetricKey(symmetricKey: try! SymmetricKey.deriveFromSeed(withSeedString: seed, recipe: recipe))
            case .UnsealingKey:
                return DerivedValueUnsealingKey(unsealingKey: try! UnsealingKey.deriveFromSeed(withSeedString: seed, recipe: recipe))
        }
    }
    
    func purpose() -> String?{
        if let json = recipe.parseJsonObject(){
            if let purpose = json["purpose"] as? String {
                return purpose
            }
        }
        
        return nil
    }
    
    func lengthInChars() -> Int?{
        if let json = recipe.parseJsonObject(){
            if let lengthInChars = json["lengthInChars"] as? Int {
                return lengthInChars
            }
        }
        
        return nil
    }
    
    func lengthInBytes() -> Int?{
        if let json = recipe.parseJsonObject(){
            if let lengthInBytes = json["lengthInBytes"] as? Int {
                return lengthInBytes
            }
        }
        
        return nil
    }
}


// Deprecated
let derivablePasswordTemplates = derivationRecipeTemplates
    .filter { $0.type == .Password }

let derivableTemplates = derivationRecipeTemplates

