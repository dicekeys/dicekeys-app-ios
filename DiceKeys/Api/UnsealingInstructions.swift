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

    static func fromJson(_ json: Data) -> UnsealingInstructions? {
        return try! JSONDecoder().decode(UnsealingInstructions.self, from: json)
    }

    static func fromJson(_ json: String) -> UnsealingInstructions? {
        return fromJson(json.data(using: .utf8)!)
    }
}
