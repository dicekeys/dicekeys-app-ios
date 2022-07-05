//
//  ApiRequestResultPreviewView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/18.
//

import SwiftUI
import SeededCrypto

/// Display derived data as a combination of a recipe field (used to derive the necessary secrets)
/// and a field that will be sent back to the caller (e.g. a derived password, key, or decrypted message.)
private struct RequestDataView: View {
    let recipe: String
    let title: String?
    let value: String?
    var lineLimit: Int = 2
    
    var body: some View {
        VStack(alignment: .center) {
            Text("recipe:")
                .italic()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(recipe)
                .minimumScaleFactor(0.2)
                .lineLimit(lineLimit)
                .padding(3)
                .border(Color.black/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1)
                .padding(.bottom, 10)
            if let title = title, let value = value {
                Text(title)
                    .italic()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(value)
                    .padding(3)
                    .minimumScaleFactor(0.2)
                    .lineLimit(lineLimit)
                    .border(Color.black/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1)
                    
            }
        }
        
    }
}

/// Preview a derived password
private struct RequestPreviewPassword: View {
    let password: Password
    var body: some View {
        RequestDataView(recipe: password.recipe, title: "password created:", value: password.password)
    }
}

/// Preview a derived secret
private struct RequestPreviewSecret: View {
    let secret: Secret
    var body: some View {
        RequestDataView(recipe: secret.recipe, title: "secret created:", value: secret.secretBytes().asHexString, lineLimit: 1)
    }
}

/// Preview a derived cryptographic key
private struct RequestPreviewGetKey: View {
    let recipe: String
    let key: Data?
    
    init(recipe: String, key: Data? = nil) {
        self.recipe = recipe
        self.key = key
    }
    
    var body: some View {
        RequestDataView(recipe: recipe, title: "key created:", value: key?.asHexString, lineLimit: 1)
    }

    init(_ sealingKey: SealingKey) {
        self.init(recipe: sealingKey.recipe, key: nil)
    }
    
    init(_ key: SymmetricKey) {
        self.init(recipe: key.recipe, key: key.keyBytes)
    }
    
    init(_ key: UnsealingKey) {
        self.init(recipe: key.recipe, key: key.unsealingKeyBytes)
    }
    
    init(_ key: SigningKey) {
        self.init(recipe: key.recipe, key: key.signingKeyBytes)
    }
    
    init (_ key: SignatureVerificationKey) {
        self.init(recipe: key.recipe, key: key.signatureVerificationKeyBytes)
    }
}

private struct RequestPreviewGenerateSignature: View {
    let request: ApiRequestGenerateSignature
    
    var body: some View {
        RequestDataView(recipe: request.recipeJson ?? "", title: "message to sign:", value: request.message.asReadableString, lineLimit: 4)
    }
}

/// Preview data to be sealed with a symmetric key
private struct RequestPreviewSealWithSymmetricKey: View {
    let recipe: String
    let plaintext: Data
    
    var body: some View {
        RequestDataView(recipe: recipe, title: "message to seal:", value: plaintext.asReadableString, lineLimit: 4)
    }
    
    init(_ request: ApiRequestSealWithSymmetricKey) {
        recipe = request.recipeJson ?? ""
        plaintext = request.plaintext
    }
}

/// Preview data to be unsealed
private struct RequestPreviewSealUnseal: View {
    let recipe: String
    let plaintext: Data
    
    var body: some View {
        RequestDataView(recipe: recipe, title: "message to seal:", value: plaintext.asReadableString, lineLimit: 4)
    }
    
    init(_ request: ApiRequestUnsealWithSymmetricKey, plaintext: Data) {
        recipe = request.recipeJson ?? ""
        self.plaintext = plaintext
    }
    init(_ request: ApiRequestUnsealWithUnsealingKey, plaintext: Data) {
        recipe = request.recipeJson ?? ""
        self.plaintext = plaintext
    }
}

/// A view to preview the result of an API request.
/// For example, if an app requested a password derived from the user's DiceKey,
/// this preview would display the password to be shared.
struct ApiRequestResultPreviewView: View {
    let request: ApiRequest
    let diceKey: DiceKey

    @ObservedObject var apiResultObservable: BackgroundCalculationOfApiRequestResult // = ObservableApiRequestResult.get(request: request, seedString: diceKey.toSeed())
    
    init(
        request: ApiRequest,
        diceKey: DiceKey
    ) {
        self.request = request
        self.diceKey = diceKey
        self._apiResultObservable = ObservedObject(initialValue: BackgroundCalculationOfApiRequestResult.get(request: request, seedString: diceKey.toSeed()))
    }
    
    var body: some View {
        VStack {
            if case let .success(successResponse) = self.apiResultObservable.result {
                DiceKeyView(diceKey: diceKey)
                .frame(maxWidth: WindowDimensions.shorterSide/2)
                switch successResponse {
                case .generateSignature:
                    if let generateSignatureRequest = self.request as? ApiRequestGenerateSignature {
                        RequestPreviewGenerateSignature(request: generateSignatureRequest)
                    }
                case .getPassword(let passwordJson):
                    RequestPreviewPassword(password: try! Password.from(json: passwordJson))
                case .getSecret(let secretJson):
                    RequestPreviewSecret(secret: try! Secret.from(json: secretJson))
                case .getSealingKey(let sealingKeyJson):
                    RequestPreviewGetKey(try! SealingKey.from(json: sealingKeyJson))
                case .getSignatureVerificationKey(let signatureVerificationKeyJson):
                    RequestPreviewGetKey(try! SignatureVerificationKey.from(json: signatureVerificationKeyJson))
                case .getSigningKey(let signingKeyJson):
                    RequestPreviewGetKey(try! SigningKey.from(json: signingKeyJson))
                case .getSymmetricKey(let symmetricKeyJson):
                    RequestPreviewGetKey(try! SymmetricKey.from(json: symmetricKeyJson))
                case .getUnsealingKey(let unsealingKeyJson):
                    RequestPreviewGetKey(try! UnsealingKey.from(json: unsealingKeyJson))
                case .sealWithSymmetricKey(_):
                    if let r = request, r is ApiRequestSealWithSymmetricKey {
                        RequestPreviewSealWithSymmetricKey(r as! ApiRequestSealWithSymmetricKey)
                    }
                case .unsealWithSymmetricKey(let plaintext):
                    if let r = request, r is ApiRequestUnsealWithSymmetricKey {
                        RequestPreviewSealUnseal(r as! ApiRequestUnsealWithSymmetricKey, plaintext: plaintext)
                    }
                case .unsealWithUnsealingKey(let plaintext):
                    if let r = request, r is ApiRequestUnsealWithUnsealingKey {
                        RequestPreviewSealUnseal(r as! ApiRequestUnsealWithUnsealingKey, plaintext: plaintext)
                    }
                }
            } else {
                Text("Loading result preview...")
            }
        }
    }
}


struct ApiRequestResultPreviewView_Previews: PreviewProvider {
    
    static func recipeForGetCommand(command: String) -> String {
        "https://dicekeys.app/?command=\(command)&requestId=1&respondTo=https%3A%2F%2Fpwmgr.app%2F--derived-secret-api--%2F&recipe=%7B%22allow%22%3A%5B%7B%22host%22%3A%22pwmgr.app%22%7D%5D%7D&recipeMayBeModified=false"
    }
    
    
    @State static var testRequestForPassword =  try! testConstructUrlApiRequest(recipeForGetCommand(command: "getPassword"))!
    
    static var previews: some View {
        ApiRequestResultPreviewView(request: testRequestForPassword, diceKey: DiceKey.Example)
    }
}
