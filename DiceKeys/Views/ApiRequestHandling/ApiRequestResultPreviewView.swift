//
//  ApiRequestResultPreviewView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/18.
//

import SwiftUI
import SeededCrypto

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
                .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                .padding(.bottom, 10)
            if let title = title, let value = value {
                Text(title)
                    .italic()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(value)
                    .minimumScaleFactor(0.2)
                    .lineLimit(lineLimit)
                    .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
        }
        
    }
}

private struct RequestPreviewPassword: View {
    let password: Password
    var body: some View {
        RequestDataView(recipe: password.recipe, title: "password created:", value: password.password)
    }
}

private struct RequestPreviewSecret: View {
    let secret: Secret
    var body: some View {
        RequestDataView(recipe: secret.recipe, title: "secret created:", value: secret.secretBytes().asHexString, lineLimit: 1)
    }
}

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
}

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

struct ApiRequestResultPreviewView: View {
    @Binding var request: ApiRequest
    let diceKey: DiceKey

    @ObservedObject var apiResultObservable: BackgroundCalculationOfApiRequestResult // = ObservableApiRequestResult.get(request: request, seedString: diceKey.toSeed())
    
    init(
        request: Binding<ApiRequest>,
        diceKey: DiceKey
    ) {
        self._request = request
        self.diceKey = diceKey
        self._apiResultObservable = ObservedObject(initialValue: BackgroundCalculationOfApiRequestResult.get(request: request.wrappedValue, seedString: diceKey.toSeed()))
    }
    
    var body: some View {
        VStack {
            if self.apiResultObservable.ready, case let .success(successResponse) = self.apiResultObservable.result {
                DiceKeyView(diceKey: diceKey)
                .frame(maxWidth: WindowDimensions.shorterSide/2)
                switch successResponse {
        //        case .generateSignature(let signature, let signatureVerificationKeyJson):
                case .getPassword(let passwordJson):
                    RequestPreviewPassword(password: try! Password.from(json: passwordJson))
                case .getSecret(let secretJson):
                    RequestPreviewSecret(secret: try! Secret.from(json: secretJson))
                case .getSealingKey(let sealingKeyJson):
                    RequestPreviewGetKey(try! SealingKey.from(json: sealingKeyJson))
        //        case .getSigningKey(let signingKeyJson):
        //        case .getSignatureVerificationKey(let signatureVerificationKeyJson):
                case .getSymmetricKey(let symmetricKeyJson):
                    RequestPreviewGetKey(try! SymmetricKey.from(json: symmetricKeyJson))
        //        case .getUnsealingKey(let unsealingKeyJson):
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
                default:
                    EmptyView()
                }
            } else {
                Text("Loading result preview...")
            }
        }
    }
}


//struct ApiRequestResultPreviewView_Previews: PreviewProvider {
//    static var previews: some View {
//        ApiRequestResultPreviewView()
//    }
//}
