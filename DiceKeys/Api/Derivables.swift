//
//  Derivables.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import Foundation

func hostRestrictions(_ hosts: [String]) -> String {
    return hosts.map { host in "{\"host\":\"*.\(host)\"}" }
        .joined(separator: ",")
}

func restrictionsJson(_ hosts: String...) -> String {
    return "{\"allow\":[\(hostRestrictions(hosts))]}"
}

struct Derivable: Codable, Identifiable {
    let name: String
    let hosts: [String]
    
    var id: String { name }

    init(_ name: String, _ hosts: String...) {
        self.name = name
        self.hosts = hosts
    }

    func getDerivationOptionsJson(iteration: Int = 1) -> String {
        return "{\"allow\":[\(hostRestrictions(hosts))]\(iteration == 1 ? "" : ",\"#\"=\(iteration)")}"
    }

    static func listFromJson(_ json: String) throws -> [Derivable]? {
        return try JSONDecoder().decode([Derivable].self, from: json.data(using: .utf8)! )
    }
    static func listToJson(_ derivables: [Derivable]) throws -> String { String(decoding: try JSONEncoder().encode(derivables), as: UTF8.self) }
}

let PasswordDerivable: [Derivable] = [
    Derivable("1Password", "1password.com"),
    Derivable("Apple", "apple.com", "icloud.com"),
    Derivable("Authy", "authy.com"),
    Derivable("Bitwarden", "bitwarden.com"),
    Derivable("Facebook", "facebook.com"),
    Derivable("Google", "google.com"),
    Derivable("Keeper", "keepersecurity.com", "keepersecurity.eu"),
    Derivable("LastPass", "lastpass.com"),
    Derivable("Microsoft", "microsoft.com", "live.com")
]
