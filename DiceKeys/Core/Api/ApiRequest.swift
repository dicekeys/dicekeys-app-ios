//
//  File.swift
//  
//
//  Created by Stuart Schechter on 2020/11/15.
//

import Foundation
import SeededCrypto

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

    static func from(json: Data) throws -> PackagedSealedMessageJsonObject {
        return try JSONDecoder().decode(PackagedSealedMessageJsonObject.self, from: json)
    }

    static func from(json: String) throws -> PackagedSealedMessageJsonObject {
        return try from(json: json.data(using: .utf8)!)
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

    func execute(seedString: String) throws -> SuccessResponse
}

extension ApiRequest {
    var allowNilEmptyDerivationOptions: Bool { get { false } }
    var derivationOptionsJsonMayBeModifiedDefault: Bool { get { false } }

    var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { true } }

    func execute(seedString: String) throws -> SuccessResponse { throw RequestException.NotImplemented }

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
    guard let derivationOptions = try DerivationOptions.fromJson(derivationOptionsJson!) else {
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
        self.derivationOptions = try getDerivationOptions(json: self.derivationOptionsJson)
        try throwIfNotAuthorized()
    }

    init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.requestContext = requestContext
        self.derivationOptionsJson = unmarshaller.optionalField(name: "derivationOptionsJson")
        self.derivationOptions = try getDerivationOptions(json: self.derivationOptionsJson)
        let derivationOptionsJsonMayBeModified = unmarshaller.optionalField(name: "derivationOptionsJsonMayBeModified")
        self.derivationOptionsJsonMayBeModifiedParameter = derivationOptionsJsonMayBeModified == "true" ? true : derivationOptionsJsonMayBeModified == "false" ? false : nil
        try throwIfNotAuthorized()
    }
}

class ApiRequestGenerateSignature: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command: ApiCommand = ApiCommand.generateSignature
    let message: Data

    init(requestContext: RequestContext, message: Data, derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool) throws {
        self.message = message
        try super.init(requestContext: requestContext, derivationOptionsJson: derivationOptionsJson, derivationOptionsJsonMayBeModified: derivationOptionsJsonMayBeModified)
    }

    override init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.message = base64urlDecode(try unmarshaller.requiredField(name: "message"))!
        try super.init(requestContext: requestContext, unmarshaller: unmarshaller)
    }

    func execute(seedString: String) throws -> SuccessResponse {
        let signingKey = try SigningKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson ?? "")
        let signature = try signingKey.generateSignature(with: message)
        return SuccessResponse.generateSignature(signature: base64urlEncode(signature), signatureVerificationKeyJson: signingKey.signatureVerificationKey.toJson())
    }
}

class ApiRequestGetPassword: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getPassword
    let requireClientMayRetrieveKeyToBeSetToTrue = false

    func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getPassword(passwordJson:
            try Password.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .toJson()
        )
    }
}

class ApiRequestGetSecret: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSecret
    let requireClientMayRetrieveKeyToBeSetToTrue = false

    func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSecret(secretJson:
            try Secret.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .toJson()
        )
    }
}
class ApiRequestGetSealingKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command: ApiCommand = ApiCommand.getSealingKey
    let allowNilEmptyDerivationOptions = false
    let requireClientMayRetrieveKeyToBeSetToTrue = false
    let derivationOptionsJsonMayBeModifiedDefault = true

    func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSealingKey(sealingKeyJson:
            try SealingKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .toJson()
        )
    }
}

class ApiRequestGetSignatureVerificationKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSignatureVerificationKey
    let requireClientMayRetrieveKeyToBeSetToTrue = false
}

class ApiRequestGetSigningKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSigningKey
    let requireClientMayRetrieveKeyToBeSetToTrue = true

    func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSigningKey(signingKeyJson:
            try SigningKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .toJson()
        )
    }
}
class ApiRequestGetSymmetricKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getSymmetricKey
    let requireClientMayRetrieveKeyToBeSetToTrue = true

    func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSymmetricKey(symmetricKeyJson:
            try SymmetricKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .toJson()
        )
    }
}
class ApiRequestGetUnsealingKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.getUnsealingKey
    let requireClientMayRetrieveKeyToBeSetToTrue = true

    func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getUnsealingKey(unsealingKeyJson:
            try UnsealingKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .toJson()
        )
    }
}

class ApiRequestSealWithSymmetricKey: ApiRequestWithExplicitDerivationOptions, ApiRequestCommand {
    let command = ApiCommand.sealWithSymmetricKey
    let plaintext: Data
    let requireClientMayRetrieveKeyToBeSetToTrue = false
    let derivationOptionsJsonMayBeModifiedDefault = true

    init(requestContext: RequestContext, derivationOptionsJson: String?, derivationOptionsJsonMayBeModified: Bool, plaintext: Data) throws {
        self.plaintext = plaintext
        try super.init(requestContext: requestContext, derivationOptionsJson: derivationOptionsJson, derivationOptionsJsonMayBeModified: derivationOptionsJsonMayBeModified)
    }

    override init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.plaintext = base64urlDecode(try unmarshaller.requiredField(name: "plaintext"))!
        try super.init(requestContext: requestContext, unmarshaller: unmarshaller)
    }

    func execute(seedString: String) throws -> SuccessResponse {
        let packagedSealedMessage = try SymmetricKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
            .seal(withMessage: "FIXME")// FIXME .seal(withMessage: plaintext)
        return SuccessResponse.sealWithSymmetricKey(packagedSealedMessageJson: packagedSealedMessage.toJson())
    }
}

private func getPackagedSealedMessageJsonObject(json packagedSealedMessageJson: String) throws -> PackagedSealedMessageJsonObject {
    do {
        return try PackagedSealedMessageJsonObject.from(json: packagedSealedMessageJson)
    } catch {
        throw RequestException.InvalidPackagedSealedMessage
    }
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
    func unsealingInstructions() throws -> UnsealingInstructions? {
        if let unsealingInstructionsJson = packagedSealedMessage.unsealingInstructions {
            return try? UnsealingInstructions.fromJson(unsealingInstructionsJson)
        }
        return nil
    }

    fileprivate init(requestContext: RequestContext, packagedSealedMessageJson: String) throws {
        self.requestContext = requestContext
        self.packagedSealedMessageJson = packagedSealedMessageJson
        let packagedSealedMessage = try getPackagedSealedMessageJsonObject(json: packagedSealedMessageJson)
        self.packagedSealedMessage = packagedSealedMessage
        self.derivationOptions = try getDerivationOptions(json: packagedSealedMessage.derivationOptionsJson)
        try throwIfNotAuthorized()
    }

    fileprivate init(requestContext: RequestContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.requestContext = requestContext
        self.packagedSealedMessageJson = try unmarshaller.requiredField(name: "packagedSealedMessageJson")
        let packagedSealedMessage = try getPackagedSealedMessageJsonObject(json: packagedSealedMessageJson)
        self.packagedSealedMessage = packagedSealedMessage
        self.derivationOptions = try getDerivationOptions(json: packagedSealedMessage.derivationOptionsJson)
        try throwIfNotAuthorized()
    }

    func throwIfNotAuthorized(requestContext: RequestContext) throws {
        let unsealingInstructions = try self.unsealingInstructions()
        guard requestContext.satisfiesAuthenticationRequirements(
            of: derivationOptions,
            allowNullRequirement:
                // Okay to have no authentication requiements in derivation options if the unsealing instructions have authentiation requirements
                (allowNilEmptyDerivationOptions && unsealingInstructions?.allow != nil)
        ) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.DerivationOptions)
        }
        if unsealingInstructions != nil {
            guard requestContext.satisfiesAuthenticationRequirements(of: unsealingInstructions!, allowNullRequirement: true) else {
                throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.UnsealingInstructions)
            }
        }
    }
}

class ApiRequestUnsealWithSymmetricKey: ApiRequestUnseal, ApiRequestCommand {
    let command = ApiCommand.unsealWithSymmetricKey
    let allowNilEmptyDerivationOptions = false

    func execute(seedString: String) throws -> SuccessResponse {
        try SuccessResponse.unsealWithSymmetricKey(plaintext: base64urlEncode(
            SymmetricKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
                .unseal(withJsonPackagedSealedMessage: packagedSealedMessageJson)
        ))
    }
}
class ApiRequestUnsealWithUnsealingKey: ApiRequestUnseal, ApiRequestCommand {
    let command = ApiCommand.unsealWithUnsealingKey
    let allowNilEmptyDerivationOptions = true

    func execute(seedString: String) throws -> SuccessResponse {
        try SuccessResponse.unsealWithUnsealingKey(plaintext: base64urlEncode(
            UnsealingKey.deriveFromSeed(withSeedString: seedString, derivationOptionsJson: self.derivationOptionsJson!)
                .unseal(withJsonPackagedSealedMessage: packagedSealedMessageJson)
        ))
    }
}

private func successResponseToDictionary(successResponse: SuccessResponse) -> [String: String] {
    switch successResponse {
    case .generateSignature(signature: let signature, signatureVerificationKeyJson: let signatureVerificationKeyJson):
        return ["signature": signature, "signatureVerificationKeyJson": signatureVerificationKeyJson]
    case .getPassword(passwordJson: let passwordJson):
        return ["passwordJson": passwordJson]
    case .getSealingKey(sealingKeyJson: let sealingKeyJson):
        return ["sealingKeyJson": sealingKeyJson]
    case .getSecret(secretJson: let secretJson):
        return ["secretJson": secretJson]
    case .getSigningKey(signingKeyJson: let signingKeyJson):
        return ["signingKeyJson": signingKeyJson]
    case .getSignatureVerificationKey(signatureVerificationKeyJson: let signatureVerificationKeyJson):
        return ["signatureVerificationKeyJson": signatureVerificationKeyJson]
    case .getSymmetricKey(symmetricKeyJson: let symmetricKeyJson):
        return ["symmetricKeyJson": symmetricKeyJson]
    case .getUnsealingKey(unsealingKeyJson: let unsealingKeyJson):
        return ["unsealingKeyJson": unsealingKeyJson]
    case .sealWithSymmetricKey(packagedSealedMessageJson: let packagedSealedMessageJson):
        return ["packagedSealedMessageJson": packagedSealedMessageJson]
    case .unsealWithSymmetricKey(plaintext: let plaintext):
        return ["plaintext": plaintext]
    case .unsealWithUnsealingKey(plaintext: let plaintext):
        return ["plaintext": plaintext]
    }
}

class AuthenticationTokens {
    static var tokenToUrl: [String: String] = [:]

    static func setToken(authToken: String, replyToUrl: String) {
        tokenToUrl[authToken] = replyToUrl
    }

    static func validateToken(authToken: String, replyToUrl: String) -> Bool {
        return tokenToUrl[authToken] == replyToUrl
    }
}

class UrlRequestContext: RequestContext {
    private let getSeedString: () throws -> String

    let requestParameters: UrlParameters

    let replyToUrlString: String
    let host: String
    let path: String
    let validatedByAuthToken: Bool
    let command: ApiCommand
    let requestId: String

    var responseUrl: URLComponents

    init(getSeedString: @escaping () throws -> String, incomingRequestUrl: URL) throws {
        self.getSeedString = getSeedString
        // Create an accessor for the requests parameters to process them
        self.requestParameters = UrlParameters(url: incomingRequestUrl)

        // All requests must have a command
        guard let command = ApiCommand(rawValue: try requestParameters.requiredField(name: "command")) else {
            throw RequestException.InvalidCommand
        }
        self.command = command

        // All requests must have a requestId
        self.requestId = try requestParameters.requiredField(name: "requestId")

        // All requests must have a replyTo field with the URL to which the response
        // will be sent
        self.replyToUrlString = try requestParameters.requiredField(name: "replyTo")
        guard let replyToUrl = URLComponents(string: replyToUrlString) else {
            throw RequestException.FailedToParseReplyTo(replyToUrlString)
        }
        self.host = replyToUrl.host ?? ""
        self.path = replyToUrl.path
        self.responseUrl = replyToUrl

        // Some requests may have an authToken proving that they can receive requests sent
        // to replyTo
        if let authToken = requestParameters.optionalField(name: "authToken") {
            self.validatedByAuthToken = AuthenticationTokens.validateToken(authToken: authToken, replyToUrl: replyToUrlString)
        } else {
            self.validatedByAuthToken = false
        }

        // The rest of the request will be constructed later based on the command.
    }

    /**
     In progress
     */
    func constructRequest() throws -> ApiRequest {
        switch command {
        case ApiCommand.generateSignature:
            return try ApiRequestGenerateSignature(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getPassword:
            return try ApiRequestGetPassword(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getSealingKey:
            return try ApiRequestGetSealingKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getSecret:
            return try ApiRequestGetSecret(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getSigningKey:
            return try ApiRequestGetSigningKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getSignatureVerificationKey:
            return try ApiRequestGetSignatureVerificationKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getSymmetricKey:
            return try ApiRequestGetSymmetricKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.getUnsealingKey:
            return try ApiRequestGetUnsealingKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.sealWithSymmetricKey:
            return try ApiRequestSealWithSymmetricKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.unsealWithSymmetricKey:
            return try ApiRequestUnsealWithSymmetricKey(requestContext: self, unmarshaller: requestParameters)
        case ApiCommand.unsealWithUnsealingKey:
            return try ApiRequestUnsealWithUnsealingKey(requestContext: self, unmarshaller: requestParameters)
        }
    }

    private func execute() {
        var responseDictionary: [String: String] = [:]
        do {
            // Construct the request and validate all parameters
            let request = try constructRequest()

            // Do not allow the request to proceed unless all authorization checks pass
            try request.throwIfNotAuthorized()

            // Only after authorization checks pass can we get the seed string
            let seedString = try getSeedString()

            // Attempt to execute the request to generate a response to send
            let successResponse: SuccessResponse = try request.execute(seedString: seedString)

            // Conert the response into a dictionary
            responseDictionary = successResponseToDictionary(successResponse: successResponse)
        } catch RequestException.ClientNotAuthorized(let authenticationRequirementIn) {
            responseDictionary["exception"] = "ClientNotAuthorizedDueTo" +
                (authenticationRequirementIn == AuthenticationRequirementIn.DerivationOptions ?
                "DerivationOptions" : "UnsealingInstructions")
        } catch {
            responseDictionary["exception"] = "Unknown"
            responseDictionary["message"] = error.localizedDescription
        }

        responseDictionary["requestID"] = self.requestId

        // Put all of the response values into the URL
        for (name, value) in responseDictionary {
            self.responseUrl.queryItems?.append(URLQueryItem(name: name, value: value))
        }
        guard let url = self.responseUrl.url else {
            return
        }
        
        #if os(iOS)
        // Transmit the response
        UIApplication.shared.open(url, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly: false]) { success in
            print("Response via URL completion handler returned \(success)")
        }
        #else
        NSWorkspace.shared.open(url)
        #endif
    }
}
