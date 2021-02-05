//
//  PackagedSealedMessage.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/04.
//

import Foundation

struct PackagedSealedMessageJsonObject: Decodable {
    var derivationOptionsJson: String
    var ciphertext: String
    var unsealingInstructions: String?

    static func from(json: Data) throws -> PackagedSealedMessageJsonObject {
        return try JSONDecoder().decode(PackagedSealedMessageJsonObject.self, from: json)
    }

    static func from(json: String) throws -> PackagedSealedMessageJsonObject {
        return try from(json: json.data(using: .utf8)!)
    }
}
