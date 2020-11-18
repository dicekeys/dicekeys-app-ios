//
//  File.swift
//  
//
//  Created by Stuart Schechter on 2020/11/15.
//

import Foundation

func base64urlDecode(_ base64url: String) -> Data? {
    var base64 = base64url
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    if base64.count % 4 != 0 {
        base64.append(String(repeating: "=", count: 4 - base64.count % 4))
    }
    return Data(base64Encoded: base64)
}

func base64urlEncode(_ data: Data) -> String {
    return data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

enum AuthenticationRequirementIn {
    case DerivationOptions
    case UnsealingInstructions
}

enum RequestException: Error {
    case ClientNotAuthorized(AuthenticationRequirementIn)
    case ComamndRequiresDerivationOptionsWithClientMayRetrieveKeySetToTrue
    case NotImplemented
    case InvalidCommand
    case InvalidDerivationOptionsJson
    case InvalidPackagedSealedMessage
    case FailedToParseReplyTo(String)
    case ParameterNotFound(String)
}

struct PackagedSealedMessageJsonObject: Decodable {
    var derivationOptionsJson: String
    var ciphertext: String
    var unsealingInstructions: String?

    static func from(json: Data) -> PackagedSealedMessageJsonObject? {
        return try! JSONDecoder().decode(PackagedSealedMessageJsonObject.self, from: json)
    }

    static func from(json: String) -> PackagedSealedMessageJsonObject? {
        return from(json: json.data(using: .utf8)!)
    }
}

protocol ApiRequestCommand {
    var command: ApiCommand { get }
}

protocol ApiRequest {
    var requestContext: RequestContext { get }
    var derivationOptions: DerivationOptions { get }
    var derivationOptionsJson: String? { get }
    var derivationOptionsJsonMayBeModified: Bool { get }

    var allowNilEmptyDerivationOptions: Bool { get }
    var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get }
    var derivationOptionsJsonMayBeModifiedDefault: Bool { get }

    func throwIfNotAuthorized() throws
}

extension ApiRequest {
    var allowNilEmptyDerivationOptions: Bool { get { false } }
    var derivationOptionsJsonMayBeModifiedDefault: Bool { get { false } }

    var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { true } }

    func throwIfNotAuthorized() throws {
        let derivationOptions = self.derivationOptions

        guard !requireClientMayRetrieveKeyToBeSetToTrue || derivationOptions.clientMayRetrieveKey == true else {
            throw RequestException.ComamndRequiresDerivationOptionsWithClientMayRetrieveKeySetToTrue
        }
        guard requestContext.satisfiesAuthenticationRequirements(
            of: derivationOptions,
            allowNullRequirement:
                // Okay to have null/empty derivationOptionsJson, with no authentication requirements, when getting a sealing key
                (allowNilEmptyDerivationOptions && (derivationOptionsJson == nil || derivationOptionsJson == ""))
        ) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.DerivationOptions)
        }
    }
}

protocol ApiRequestParameterUnmarshaller {
    func optionalField(name fieldName: String) -> String?
    func requiredField(name fieldName: String) throws -> String
}

class UrlParameters: ApiRequestParameterUnmarshaller {
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

private func getDerivationOptions(json derivationOptionsJson: String?) throws -> DerivationOptions {
    if derivationOptionsJson == "" || derivationOptionsJson == nil {
        return DerivationOptions()
    }
    guard let derivationOptions = DerivationOptions.fromJson(derivationOptionsJson!) else {
        throw RequestException.InvalidDerivationOptionsJson
    }
    return derivationOptions
}

class ApiRequestWithExplicitDerivationOptions: ApiRequest {
    let derivationOptions: DerivationOptions
    let derivationOptionsJson: String?
    let requestContext: RequestContext
    let derivationOptionsJsonMayBeModifiedParameter: Bool?

    var derivationOptionsJsonMayBeModified: Bool { get {
        self.derivationOptionsJsonMayBeModifiedParameter ?? derivationOptionsJsonMayBeModifiedDefault
    }}

    init(requestContext: RequestContext, derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool?) throws {
        self.requestContext = requestContext
        self.derivationOptionsJson = derivationOptionsJson
        self.derivationOptionsJsonMayBeModifiedParameter = derivationOptionsJsonMayBeModified
        self.derivationOptions = try! getDerivationOptions(json: self.derivationOptionsJson)
        try! throwIfNotAuthorized()
    }

    init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.requestContext = requestContext
        self.derivationOptionsJson = unmarshaller.optionalField(name: "derivationOptionsJson")
        self.derivationOptions = try! getDerivationOptions(json: self.derivationOptionsJson)
        let derivationOptionsJsonMayBeModified = unmarshaller.optionalField(name: "derivationOptionsJsonMayBeModified")
        self.derivationOptionsJsonMayBeModifiedParameter = derivationOptionsJsonMayBeModified == "true" ? true : derivationOptionsJsonMayBeModified == "false" ? false : nil
        try! throwIfNotAuthorized()
    }
}

class ApiRequestGenerateSignature: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command: ApiCommand = ApiCommand.generateSignature
    let message: Data

    init(requestContext: RequestContext, message: Data, derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool) throws {
        self.message = message
        try! super.init(requestContext: requestContext, derivationOptionsJson: derivationOptionsJson, derivationOptionsJsonMayBeModified: derivationOptionsJsonMayBeModified)
    }

    override init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.message = base64urlDecode(try! unmarshaller.requiredField(name: "message"))!
        try! super.init(requestContext: requestContext, unmarshaller: unmarshaller)
    }
}

class ApiRequestGetPassword: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getPassword
    let requireClientMayRetrieveKeyToBeSetToTrue = false
}
class ApiRequestGetSecret: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSecret
    let requireClientMayRetrieveKeyToBeSetToTrue = false
}
class ApiRequestGetSealingKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command: ApiCommand = ApiCommand.getSealingKey
    let allowNilEmptyDerivationOptions = false
    let requireClientMayRetrieveKeyToBeSetToTrue = false
    let derivationOptionsJsonMayBeModifiedDefault = true
}
class ApiRequestGetSignatureVerificationKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSignatureVerificationKey
    let requireClientMayRetrieveKeyToBeSetToTrue = false
}
class ApiRequestGetSigningKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSigningKey
    let requireClientMayRetrieveKeyToBeSetToTrue = true
}
class ApiRequestGetSymmetricKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSymmetricKey
    let requireClientMayRetrieveKeyToBeSetToTrue = true
}
class ApiRequestGetUnsealingKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getUnsealingKey
    let requireClientMayRetrieveKeyToBeSetToTrue = true
}

class ApiRequestSealWithSymmetricKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.sealWithSymmetricKey
    let plaintext: Data
    let requireClientMayRetrieveKeyToBeSetToTrue = false
    let derivationOptionsJsonMayBeModifiedDefault = true

    init(requestContext: RequestContext, derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool, plaintext: Data) throws {
        self.plaintext = plaintext
        try! super.init(requestContext: requestContext, derivationOptionsJson: derivationOptionsJson, derivationOptionsJsonMayBeModified: derivationOptionsJsonMayBeModified)
    }

    override init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.plaintext = base64urlDecode(try! unmarshaller.requiredField(name: "plaintext"))!
        try! super.init(requestContext: requestContext, unmarshaller: unmarshaller)
    }
}

private func getPackagedSealedMessage(json packagedSealedMessageJson: String) throws -> PackagedSealedMessageJsonObject {
    guard let packagedSealedMessage = PackagedSealedMessageJsonObject.from(json: packagedSealedMessageJson) else {
        throw RequestException.InvalidPackagedSealedMessage
    }
    return packagedSealedMessage
}

class ApiRequestUnseal: ApiRequest {
    let requestContext: RequestContext
    let packagedSealedMessage: PackagedSealedMessageJsonObject
    let packagedSealedMessageJson: String
    let derivationOptions: DerivationOptions

    let derivationOptionsJsonMayBeModified = false
    let requireClientMayRetrieveKeyToBeSetToTrue = false

    var derivationOptionsJson: String? { get {
        return self.packagedSealedMessage.derivationOptionsJson
    }}
    var unsealingInstructions: UnsealingInstructions? { get {
        if let unsealingInstructionsJson = packagedSealedMessage.unsealingInstructions {
            return UnsealingInstructions.fromJson(unsealingInstructionsJson)
        }
        return nil
    }}

    fileprivate init(requestContext: RequestContext, packagedSealedMessageJson: String) throws {
        self.requestContext = requestContext
        self.packagedSealedMessageJson = packagedSealedMessageJson
        let packagedSealedMessage = try! getPackagedSealedMessage(json: packagedSealedMessageJson)
        self.packagedSealedMessage = packagedSealedMessage
        self.derivationOptions = try! getDerivationOptions(json: packagedSealedMessage.derivationOptionsJson)
        try! throwIfNotAuthorized()
    }

    fileprivate init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.requestContext = requestContext
        self.packagedSealedMessageJson = try! unmarshaller.requiredField(name: "packagedSealedMessageJson")
        let packagedSealedMessage = try! getPackagedSealedMessage(json: packagedSealedMessageJson)
        self.packagedSealedMessage = packagedSealedMessage
        self.derivationOptions = try! getDerivationOptions(json: packagedSealedMessage.derivationOptionsJson)
        try! throwIfNotAuthorized()
    }

    func throwIfNotAuthorized(requestContext: RequestContext) throws {
        guard requestContext.satisfiesAuthenticationRequirements(
            of: derivationOptions,
            allowNullRequirement:
                // Okay to have no authentication requiements in derivation options if the unsealing instructions have authentiation requirements
                (allowNilEmptyDerivationOptions && unsealingInstructions?.allow != nil)
        ) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.DerivationOptions)
        }
        if let unsealingInstructions = self.unsealingInstructions {
            guard requestContext.satisfiesAuthenticationRequirements(of: unsealingInstructions, allowNullRequirement: true) else {
                throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.UnsealingInstructions)
            }
        }
    }
}

class ApiRequestUnsealWithSymmetricKey: ApiRequestUnseal, ApiRequestCommand {
    let command = ApiCommand.unsealWithSymmetricKey
    let allowNilEmptyDerivationOptions = false
}
class ApiRequestUnsealWithUnsealingKey: ApiRequestUnseal, ApiRequestCommand {
    let command = ApiCommand.unsealWithUnsealingKey
    let allowNilEmptyDerivationOptions = true
}

/**
 In progress
 */
func handleApiRequest(incomingRequestUrl: URL) throws {
    let p = UrlParameters(url: incomingRequestUrl)
    let replyTo = try! p.requiredField(name: "replyTo")
    guard let replyToUrl = URL(string: replyTo) else {
        throw RequestException.FailedToParseReplyTo(replyTo)
    }
    let authToken = p.optionalField(name: "authToken")
    var validatedByAuthToken = false
    if let authTokenNonNil = authToken {
        // FIXME
        if authTokenNonNil == "FIXME" {
            validatedByAuthToken = true
        }
    }

    let requestContext = RequestContext(url: replyToUrl, validatedByAuthToken: validatedByAuthToken)
    guard let command = ApiCommand(rawValue: try! p.requiredField(name: "command")) else {
        throw RequestException.InvalidCommand
    }
    switch command {
    case ApiCommand.generateSignature:
        try! ApiRequestGenerateSignature(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getPassword:
        try! ApiRequestGetPassword(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getSealingKey:
        try! ApiRequestGetSealingKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getSecret:
        try! ApiRequestGetSecret(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getSigningKey:
        try! ApiRequestGetSigningKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getSignatureVerificationKey:
        try! ApiRequestGetSignatureVerificationKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getSymmetricKey:
        try! ApiRequestGetSymmetricKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.getUnsealingKey:
        try! ApiRequestGetUnsealingKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.sealWithSymmetricKey:
        try! ApiRequestSealWithSymmetricKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.unsealWithSymmetricKey:
        try! ApiRequestUnsealWithSymmetricKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    case ApiCommand.unsealWithUnsealingKey:
        try! ApiRequestUnsealWithUnsealingKey(requestContext: requestContext, unmarshaller: p).throwIfNotAuthorized()
    }
}
