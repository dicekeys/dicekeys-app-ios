//
//  UrlApiRequest.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/04.
//

import Foundation
import Combine
import SeededCrypto

private func successResponseToDictionary(successResponse: SuccessResponse) -> [String: String] {
    switch successResponse {
    case .generateSignature(signature: let signature, signatureVerificationKeyJson: let signatureVerificationKeyJson):
        return ["signature": base64urlEncode(signature), "signatureVerificationKeyJson": signatureVerificationKeyJson]
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
        return ["plaintext": base64urlEncode(plaintext)]
    case .unsealWithUnsealingKey(plaintext: let plaintext):
        return ["plaintext": base64urlEncode(plaintext)]
    }
}

fileprivate class UrlRequestSecurityContext: RequestSecurityContext {
    let respondToUrlString: String
    var responseUrl: URLComponents
    let host: String
    let path: String
    let validatedByAuthToken: Bool

    init(requestParameters: UrlParameterUnmarshaller) throws {
        self.respondToUrlString = try requestParameters.requiredField(name: "respondTo")
        guard let respondToUrl = URLComponents(string: respondToUrlString) else {
            throw RequestException.FailedToParseReplyTo(respondToUrlString)
        }
        
        self.host = respondToUrl.host ?? ""
        self.path = respondToUrl.path
        self.responseUrl = respondToUrl

        // Some requests may have an authToken proving that they can receive requests sent
        // to replyTo
        if let authToken = requestParameters.optionalField(name: "authToken") {
            self.validatedByAuthToken = AuthenticationTokens.validateToken(authToken: authToken, replyToUrl: respondToUrlString)
        } else {
            self.validatedByAuthToken = false
        }
    }
}

fileprivate func sendResponse(_ responseUrl: URLComponents, _ additionalParameters: [String:String]) {
    var mutableResponseUrl = responseUrl
    for (name, value) in additionalParameters {
        mutableResponseUrl.queryItems?.append(URLQueryItem(name: name, value: value))
    }

    guard let url = mutableResponseUrl.url else {
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

func testConstructUrlApiRequest(_ requestUrlString: String) throws -> ApiRequest? {
    let requestUrl = URL(string: requestUrlString)!
    let parameterUnmarshaller = UrlParameterUnmarshaller(url: requestUrl)

    return try constructApiRequest(
        id: requestUrlString,
        securityContext: try UrlRequestSecurityContext(requestParameters: parameterUnmarshaller),
        unmarshaller: parameterUnmarshaller
    )
}



// Handles API requests arriving via URL
func handleUrlApiRequest(
    incomingRequestUrl: URL,
    approveApiRequest: @escaping (_ forRequest: ApiRequest, _ callback: @escaping (Result</* seed */String, Error>) -> Void) -> Void,
    // Set only for testing, otherwise, use the default
    sendResponse: @escaping (_ responseUrl: URLComponents, _ additionalParameters: [String:String]) -> Void = sendResponse
) {
    // This function sends an error via the sendResponse call.
    // It's defined inside this function so that it can use the injected sendResponse function
    func sendError(_ responseUrl: URLComponents, _ error: Error) {
        switch error {
        case RequestException.ClientNotAuthorized(let authenticationRequirementIn):
            sendResponse(responseUrl, ["exception": "ClientNotAuthorizedDueTo" +
                (authenticationRequirementIn == AuthenticationRequirementIn.DerivationOptions ?
                    "DerivationOptions" : "UnsealingInstructions")
            ])
        default:
            sendResponse(responseUrl, ["exception": "Unknown", "message": error.localizedDescription])
        }
    }
    
    // The unmarhsaller turns the URL into a set of parameters
    let parameterUnmarshaller = UrlParameterUnmarshaller(url: incomingRequestUrl)
    
    guard let securityContext = try? UrlRequestSecurityContext(requestParameters: parameterUnmarshaller) else {
        // Not reply-to to send a response to, so just have to fail silently (no response)
        return
    }
    
    guard let requestId = parameterUnmarshaller.optionalField(name: "requestId") else {
        // No requestId to associate with this request, so just have to fail silently (no response)
        return
    }

    var responseUrl = securityContext.responseUrl
    responseUrl.queryItems?.append(URLQueryItem(name: "requestId", value: requestId))

    do {
        var request = try constructApiRequest(id: incomingRequestUrl.absoluteString,securityContext: securityContext, unmarshaller: parameterUnmarshaller)

        // Do not allow the request to proceed unless all authorization checks pass
        // try request.throwIfNotAuthorized()

        // Only after authorization checks pass can we get the seed string
        approveApiRequest(request) { result in
            switch result {
            case .failure(let error):
                sendError(responseUrl, error)
            case .success(let seedString):
                _ = BackgroundCalculationOfApiRequestResult.get(request: request, seedString: seedString).future.sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            sendError(responseUrl, error)
                        }
                    },
                    receiveValue: {successResponse in
                        sendResponse(responseUrl, successResponseToDictionary(successResponse: successResponse))
                    })
//                switch (request.executeWithCachedResult(seedString: seedString)) {
//                case .success(let successResponse):
//                    sendResponse(responseUrl, successResponseToDictionary(successResponse: successResponse))
//                case .failure(let error):
//                    sendError(responseUrl, error)
//                }
            }
        }
    } catch {
        sendError(responseUrl, error)
    }
}
