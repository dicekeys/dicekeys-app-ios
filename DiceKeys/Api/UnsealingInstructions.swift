//
//  UnsealingInstructions.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

struct UnsealingInstructions: AuthenticationRequirements, Codable {
    var allow: [WebBasedApplicationIdentity]?
    var requireAuthenticationHandshake: Bool?
    var allowAndroidPrefixes: [String]?

    static func fromJson(_ json: Data) throws -> UnsealingInstructions? {
        return try JSONDecoder().decode(UnsealingInstructions.self, from: json)
    }

    static func fromJson(_ json: String) throws -> UnsealingInstructions? {
        return try fromJson(json.data(using: .utf8)!)
    }
}
