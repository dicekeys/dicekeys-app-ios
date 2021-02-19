//
//  File.swift
//  
//
//  Created by Stuart Schechter on 2020/11/15.
//

import Foundation
import SeededCrypto
enum AuthenticationRequirementIn {
    case Recipe
    case UnsealingInstructions
}

enum RequestException: Error {
    case UserDeclinedToAuthorizeOperation
    case ClientNotAuthorized(AuthenticationRequirementIn)
    case ComamndRequiresRecipeWithClientMayRetrieveKeySetToTrue
    case NotImplemented
    case InvalidCommand
    case InvalidRecipeJson
    case InvalidPackagedSealedMessage
    case FailedToParseReplyTo(String)
    case ParameterNotFound(String)
}

protocol ApiRequestCommand {
    var command: ApiCommand { get }
}

protocol ApiRequest {
    var id: String { get }
    var securityContext: RequestSecurityContext { get }
    var recipeObj: SeededCryptoRecipeObject { get }
    var recipeJson: String? { get }
    var recipeMayBeModified: Bool { get }

    var allowNilEmptyRecipe: Bool { get }
    var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get }
    var recipeMayBeModifiedDefault: Bool { get }

    func throwIfNotAuthorized() throws

    /// Calculate the result of the API call, throwing an exception if it fails
    func execute(seedString: String) throws -> SuccessResponse
//
//    // Wrap the execute function to return a Result instead of throwing
//    func executeIntoResult(seedString: String) -> Result<SuccessResponse, Error>
//
//    var resultCache: [String: Result<SuccessResponse, Error>] {get set}
//    // Wrap the execute function to cache the result in a Result object
//    // so that it only ever needs to be calculated once
//    mutating func executeWithCachedResult(seedString: String) -> Result<SuccessResponse, Error>

}

extension ApiRequest {
    var allowNilEmptyRecipe: Bool { get { false } }

    func throwIfNotAuthorized() throws {
        let recipeObj = self.recipeObj

        if (requireClientMayRetrieveKeyToBeSetToTrue && recipeObj.clientMayRetrieveKey != true) {
            throw RequestException.ComamndRequiresRecipeWithClientMayRetrieveKeySetToTrue
        }
        guard securityContext.satisfiesAuthenticationRequirements(
            of: recipeObj,
            allowNullRequirement:
                // Okay to have null/empty recipe, with no authentication requirements, when getting a sealing key
                (allowNilEmptyRecipe && (recipeJson == nil || recipeJson == ""))
        ) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.Recipe)
        }
    }
}

private func getRecipe(json recipe: String?) throws -> SeededCryptoRecipeObject {
    guard let recipe = try SeededCryptoRecipeObject.fromJson(recipe!) else {
        throw RequestException.InvalidRecipeJson
    }
    return recipe
}

class ApiRequestWithExplicitRecipe: ApiRequest {
    let id: String
    let recipeObj: SeededCryptoRecipeObject
    let recipeJson: String?
    let securityContext: RequestSecurityContext
    let recipeMayBeModifiedParameter: Bool?
//    internal var resultCache: [String: Result<SuccessResponse, Error>] = [:]
    var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { true } }
    var recipeMayBeModifiedDefault: Bool { get { false } }
    
    var recipeMayBeModified: Bool { get {
        // Whether the recipe (dervivation options) can be modified depends on whehter a parameter
        // allowing it is set or, failing that, the default for the given command type
        self.recipeMayBeModifiedParameter ?? recipeMayBeModifiedDefault
    }}
    
    func execute(seedString: String) throws -> SuccessResponse { throw RequestException.NotImplemented }

    init(id: String, securityContext: RequestSecurityContext, recipeJson: String?, recipeMayBeModified: Bool?) throws {
        self.id = id
        self.securityContext = securityContext
        self.recipeJson = recipeJson
        self.recipeMayBeModifiedParameter = recipeMayBeModified
        self.recipeObj = try getRecipe(json: self.recipeJson)
        try throwIfNotAuthorized()
    }

    init(id: String, securityContext: RequestSecurityContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.id = id
        self.securityContext = securityContext
        self.recipeJson = unmarshaller.optionalField(name: "recipe")
        self.recipeObj = try getRecipe(json: self.recipeJson)
        let recipeMayBeModified = unmarshaller.optionalField(name: "recipeMayBeModified")
        self.recipeMayBeModifiedParameter = recipeMayBeModified == "true" ? true : recipeMayBeModified == "false" ? false : nil
        try throwIfNotAuthorized()
    }
}

class ApiRequestGenerateSignature: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command: ApiCommand = ApiCommand.generateSignature
    let message: Data

    init(id: String, securityContext: RequestSecurityContext, message: Data, recipeJson: String?, recipeMayBeModified: Bool) throws {
        self.message = message
        try super.init(id: id, securityContext: securityContext, recipeJson: recipeJson, recipeMayBeModified: recipeMayBeModified)
    }

    override init(id: String, securityContext: RequestSecurityContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.message = base64urlDecode(try unmarshaller.requiredField(name: "message"))!
        try super.init(id: id, securityContext: securityContext, unmarshaller: unmarshaller)
    }

    override func execute(seedString: String) throws -> SuccessResponse {
        let signingKey = try SigningKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson ?? "")
        let signature = try signingKey.generateSignature(with: message)
        return SuccessResponse.generateSignature(signature: signature, signatureVerificationKeyJson: signingKey.signatureVerificationKey.toJson())
    }
}

class ApiRequestGetPassword: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.getPassword
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { false } }

    override func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getPassword(passwordJson:
            try Password.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
            .toJson()
        )
    }
}

class ApiRequestGetSecret: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.getSecret
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { false } }

    override func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSecret(secretJson:
            try Secret.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
            .toJson()
        )
    }
}
class ApiRequestGetSealingKey: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command: ApiCommand = ApiCommand.getSealingKey
    let allowNilEmptyRecipe = false
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { false } }
    override var recipeMayBeModifiedDefault: Bool { get { true } }
    
    override func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSealingKey(sealingKeyJson:
            try SealingKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
            .toJson()
        )
    }
}

class ApiRequestGetSignatureVerificationKey: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.getSignatureVerificationKey
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { false } }
}

class ApiRequestGetSigningKey: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.getSigningKey
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { true } }

    override func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSigningKey(signingKeyJson:
            try SigningKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
            .toJson()
        )
    }
}
class ApiRequestGetSymmetricKey: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.getSymmetricKey
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { true } }

    override func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getSymmetricKey(symmetricKeyJson:
            try SymmetricKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
            .toJson()
        )
    }
}
class ApiRequestGetUnsealingKey: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.getUnsealingKey
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { true } }

    override func execute(seedString: String) throws -> SuccessResponse {
        SuccessResponse.getUnsealingKey(unsealingKeyJson:
            try UnsealingKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
            .toJson()
        )
    }
}

class ApiRequestSealWithSymmetricKey: ApiRequestWithExplicitRecipe, ApiRequestCommand {
    let command = ApiCommand.sealWithSymmetricKey
    let plaintext: Data
    override var requireClientMayRetrieveKeyToBeSetToTrue: Bool { get { false } }
    override var recipeMayBeModifiedDefault: Bool { get { true } }

    init(id: String, securityContext: RequestSecurityContext, recipeJson: String?, recipeMayBeModified: Bool, plaintext: Data) throws {
        self.plaintext = plaintext
        try super.init(id: id, securityContext: securityContext, recipeJson: recipeJson, recipeMayBeModified: recipeMayBeModified)
    }

    override init(id: String, securityContext: RequestSecurityContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.plaintext = base64urlDecode(try unmarshaller.requiredField(name: "plaintext"))!
        try super.init(id: id, securityContext: securityContext, unmarshaller: unmarshaller)
    }

    override func execute(seedString: String) throws -> SuccessResponse {
        let packagedSealedMessage = try SymmetricKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
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
    let id: String
    let securityContext: RequestSecurityContext
    let packagedSealedMessage: PackagedSealedMessageJsonObject
    let packagedSealedMessageJson: String
    let recipeObj: SeededCryptoRecipeObject
//    internal var resultCache: [String: Result<SuccessResponse, Error>] = [:]

    var recipeMayBeModifiedDefault: Bool { get { false } }
    let recipeMayBeModified = false
    let requireClientMayRetrieveKeyToBeSetToTrue = false

    func execute(seedString: String) throws -> SuccessResponse { throw RequestException.NotImplemented }
    
    var recipeJson: String? { get {
        return self.packagedSealedMessage.recipe
    }}
    func unsealingInstructions() throws -> UnsealingInstructions? {
        if let unsealingInstructionsJson = packagedSealedMessage.unsealingInstructions {
            return try? UnsealingInstructions.fromJson(unsealingInstructionsJson)
        }
        return nil
    }

    init(id: String, securityContext: RequestSecurityContext, packagedSealedMessageJson: String) throws {
        self.id = id
        self.securityContext = securityContext
        self.packagedSealedMessageJson = packagedSealedMessageJson
        let packagedSealedMessage = try getPackagedSealedMessageJsonObject(json: packagedSealedMessageJson)
        self.packagedSealedMessage = packagedSealedMessage
        self.recipeObj = try getRecipe(json: packagedSealedMessage.recipe)
        try throwIfNotAuthorized()
    }

    init(id: String, securityContext: RequestSecurityContext, unmarshaller: ApiRequestParameterUnmarshaller) throws {
        self.id = id
        self.securityContext = securityContext
        self.packagedSealedMessageJson = try unmarshaller.requiredField(name: "packagedSealedMessageJson")
        let packagedSealedMessage = try getPackagedSealedMessageJsonObject(json: packagedSealedMessageJson)
        self.packagedSealedMessage = packagedSealedMessage
        self.recipeObj = try getRecipe(json: packagedSealedMessage.recipe)
        try throwIfNotAuthorized()
    }

    func throwIfNotAuthorized(requestContext: RequestSecurityContext) throws {
        let unsealingInstructions = try self.unsealingInstructions()
        guard requestContext.satisfiesAuthenticationRequirements(
            of: recipeObj,
            allowNullRequirement:
                // Okay to have no authentication requiements in derivation options if the unsealing instructions have authentiation requirements
                (allowNilEmptyRecipe && unsealingInstructions?.allow != nil)
        ) else {
            throw RequestException.ClientNotAuthorized(AuthenticationRequirementIn.Recipe)
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
    let allowNilEmptyRecipe = false

    override func execute(seedString: String) throws -> SuccessResponse {
        try SuccessResponse.unsealWithSymmetricKey(plaintext:
            SymmetricKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
                .unseal(withJsonPackagedSealedMessage: packagedSealedMessageJson)
        )
    }
}
class ApiRequestUnsealWithUnsealingKey: ApiRequestUnseal, ApiRequestCommand {
    let command = ApiCommand.unsealWithUnsealingKey
    let allowNilEmptyRecipe = true

    override func execute(seedString: String) throws -> SuccessResponse {
        try SuccessResponse.unsealWithUnsealingKey(plaintext: 
            UnsealingKey.deriveFromSeed(withSeedString: seedString, recipe: self.recipeJson!)
                .unseal(withJsonPackagedSealedMessage: packagedSealedMessageJson)
        )
    }
}

func constructApiRequest(
    id: String,
    securityContext: RequestSecurityContext,
    unmarshaller: ApiRequestParameterUnmarshaller
) throws -> ApiRequest {
    guard let command = ApiCommand(rawValue: try unmarshaller.requiredField(name: "command")) else {
        throw RequestException.InvalidCommand
    }
    switch command {
    case ApiCommand.generateSignature:
        return try ApiRequestGenerateSignature(id: id, securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getPassword:
        return try ApiRequestGetPassword(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getSealingKey:
        return try ApiRequestGetSealingKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getSecret:
        return try ApiRequestGetSecret(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getSigningKey:
        return try ApiRequestGetSigningKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getSignatureVerificationKey:
        return try ApiRequestGetSignatureVerificationKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getSymmetricKey:
        return try ApiRequestGetSymmetricKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.getUnsealingKey:
        return try ApiRequestGetUnsealingKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.sealWithSymmetricKey:
        return try ApiRequestSealWithSymmetricKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.unsealWithSymmetricKey:
        return try ApiRequestUnsealWithSymmetricKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    case ApiCommand.unsealWithUnsealingKey:
        return try ApiRequestUnsealWithUnsealingKey(id: id,securityContext: securityContext, unmarshaller: unmarshaller)
    }
}

func executeApiRequest(
    getSeedString: @escaping () throws -> String,
    id: String,
    securityContext: RequestSecurityContext,
    unmarshaller: ApiRequestParameterUnmarshaller
) throws -> SuccessResponse {
    // Construct the request and validate all parameters
    let request = try constructApiRequest(id: id, securityContext: securityContext, unmarshaller: unmarshaller)

    // Do not allow the request to proceed unless all authorization checks pass
    try request.throwIfNotAuthorized()

    // Only after authorization checks pass can we get the seed string
    let seedString = try getSeedString()

    // Attempt to execute the request to generate a response to send
    let successResponse: SuccessResponse = try request.execute(seedString: seedString)

    return successResponse
}
