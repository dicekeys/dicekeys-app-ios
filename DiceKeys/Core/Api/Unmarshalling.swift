//
//  Unmarshalling.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/04.
//

import Foundation

protocol ApiRequestParameterUnmarshaller {
    func optionalField(name fieldName: String) -> String?
    func requiredField(name fieldName: String) throws -> String
}

class UrlParameterUnmarshaller: ApiRequestParameterUnmarshaller {
    private let parameters: [String: String?]

    init(url: URL) {
        var queryDictionary = [String: String?]()
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for queryItem in queryItems {
                queryDictionary[queryItem.name] = queryItem.value
            }
        }
        self.parameters = queryDictionary
    }

    func optionalField(name fieldName: String) -> String? {
        return parameters[fieldName] ?? nil
    }
    func requiredField(name fieldName: String) throws -> String {
        let value = parameters[fieldName] ?? nil
        guard let nonNilValue = value else {
            throw RequestException.ParameterNotFound(fieldName)
        }
        return nonNilValue
    }
}
