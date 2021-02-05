//
//  AuthenticationTokens.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/04.
//

import Foundation

class AuthenticationTokens {
    static var tokenToUrl: [String: String] = [:]

    static func setToken(authToken: String, replyToUrl: String) {
        tokenToUrl[authToken] = replyToUrl
    }

    static func validateToken(authToken: String, replyToUrl: String) -> Bool {
        return tokenToUrl[authToken] == replyToUrl
    }
}
