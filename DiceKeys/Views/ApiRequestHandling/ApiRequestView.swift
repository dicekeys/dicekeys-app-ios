//
//  ApiRequestView.swift
//  DiceKeys (iOS)
//
//  Created by Stuart Schechter on 2021/02/06.
//

import SwiftUI
import SeededCrypto

struct RequestQuestionView: View {
    let request: ApiRequest
    
    var hostComponent: String {
        switch request.securityContext.host {
            case "apple.com": return "Apple"
            case "live.com": fallthrough
            case "microsoft.com": return "Microsoft"
            case "bitwarden.com": return "BitWarden"
            case "1password.com": return "1Password"
        default: return request.securityContext.host
    } }
    
    // FIXME  --  areRecipeSigned ? "recreate" : "create";
    var createOrRecreate: String { "create" }

    var description: String {
        request is ApiRequestGetPassword ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) a password?" :
        request is ApiRequestGetSecret ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) a secret security code?" :
        request is ApiRequestGetUnsealingKey ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) keys to encode and decode secrets?" :
        request is ApiRequestGetSymmetricKey ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) a key to encode and decode secrets?" :
        request is ApiRequestSealWithSymmetricKey ?
          "May \(hostComponent) use your DiceKey to encode a secret?" :
        request is ApiRequestUnsealWithSymmetricKey ?
          "May \(hostComponent) use your DiceKey to decode a secret?" :
        request is ApiRequestUnsealWithUnsealingKey ?
          "May \(hostComponent) use your DiceKey to decode a secret?" :
        // Less common
        request is ApiRequestGetSigningKey ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) keys to sign data?" :
        request is ApiRequestGenerateSignature ?
          "May \(hostComponent) use your DiceKey to add its digital signature to data?" :
        request is ApiRequestGetSignatureVerificationKey ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) a key used to verify data it has signed?" :
          // Uncommon
        request is ApiRequestGetSealingKey ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) keys to store secrets?" :
          ""
    }
    
    var body: some View {
        Text(description)
            .font(.title)
            .bold()
            .minimumScaleFactor(0.2)
            .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
    }
}

struct RequestDataView: View {
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

struct RequestPreviewPassword: View {
    let password: Password
    var body: some View {
        RequestDataView(recipe: password.recipe, title: "password created:", value: password.password)
    }
}

struct RequestPreviewSecret: View {
    let secret: Secret
    var body: some View {
        RequestDataView(recipe: secret.recipe, title: "secret created:", value: secret.secretBytes().asHexString, lineLimit: 1)
    }
}

struct RequestPreviewGetKey: View {
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

struct RequestPreviewSealWithSymmetricKey: View {
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

struct RequestPreviewSealUnseal: View {
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

struct RequestPreviewView: View {
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
            if self.apiResultObservable.ready, let successResponse = self.apiResultObservable.successResponse {
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

func describeApproval(_ request: ApiRequest) -> String {
    return (request is ApiRequestGetPassword) ?
       "Send Password" :
    (request is ApiRequestGetSecret) ?
       "Send Secret" :
    (request is ApiRequestGetSigningKey ||
    request is ApiRequestGetSealingKey ||
    request is ApiRequestGetUnsealingKey) ?
       "Send Keys" :
    (request is ApiRequestGetSymmetricKey ||
    request is ApiRequestGetSignatureVerificationKey) ?
       "Send Key" :
    (request is ApiRequestSealWithSymmetricKey) ?
       "Send Encoded Message" :
    (request is ApiRequestUnsealWithSymmetricKey ||
    request is ApiRequestUnsealWithUnsealingKey) ?
       "Send Encoded Message" :
    "Approve"
}

struct ApiRequestView: View {
    @Binding var request: ApiRequest
    @ObservedObject var diceKeyMemoryStore: DiceKeyMemoryStore
    
    @State var userAskedToLoadDiceKey: Bool = false
    
    var diceKeyLoaded: DiceKey? {
        diceKeyMemoryStore.diceKeyLoaded
    }
    
    var diceKeyAbsent: Bool { diceKeyLoaded == nil }
    var showLoadDiceKey: Bool { diceKeyAbsent && userAskedToLoadDiceKey }
        
    func approveRequest() {
        if let diceKey = diceKeyLoaded {
            ApiRequestState.singleton.completeApiRequest(.success(diceKey.toSeed()))
        }
    }
  
    func declineRequest() {
        ApiRequestState.singleton.completeApiRequest(.failure(RequestException.UserDeclinedToAuthorizeOperation))
    }
    
    var body: some View {
        VStack {
            Spacer()
            RequestQuestionView(request: request)
            Spacer()
            if showLoadDiceKey {
                LoadDiceKey(onDiceKeyLoaded: { diceKey, _ in
                    diceKeyMemoryStore.setDiceKey(diceKey: diceKey)
                    userAskedToLoadDiceKey = false
                }, onBack: {
                    userAskedToLoadDiceKey = false
                })
            } else if let diceKey = diceKeyLoaded {
                RequestPreviewView(request: $request, diceKey: diceKey)
            } else {
                VStack {
                    Text("To allow this action, you'll first need to load your DiceKey.")
                    Button(action: { userAskedToLoadDiceKey = true }, label: { Text("Load DiceKey") })
                }
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: { self.declineRequest() }, label: { Text("Cancel") })
                Spacer()
                Button(action: { self.declineRequest() }, label: { Text(describeApproval(request)) }).hideIf(diceKeyAbsent)
                Spacer()
            }
            Spacer()
        }.padding(.all, 5)
    }
}

struct ApiRequestView_Previews: PreviewProvider {
    
    static func recipeForGetCommand(command: String) -> String {
        "https://dicekeys.app/?command=\(command)&requestId=1&respondTo=https%3A%2F%2Fpwmgr.app%2F--derived-secret-api--%2F&recipe=%7B%22allow%22%3A%5B%7B%22host%22%3A%22pwmgr.app%22%7D%5D%7D&recipeMayBeModified=false"
    }
    
    static func recipeForGetKeyCommand(command: String) -> String {
        "https://dicekeys.app/?command=\(command)&requestId=1&respondTo=https%3A%2F%2Fpwdmgr.app%2F--derived-secret-api--%2F&recipe=%7B%22allow%22%3A%5B%7B%22host%22%3A%22pwdmgr.app%22%7D%5D%2C%22clientMayRetrieveKey%22%3Atrue%7D&recipeMayBeModified=false"
    }
    
    @State static var testRequestForPassword =  try! testConstructUrlApiRequest(recipeForGetCommand(command: "getPassword"))!
    @State static var testRequestForSecret =  try! testConstructUrlApiRequest(recipeForGetCommand(command: "getSecret"))!
    @State static var testRequestForSymmetricKey =  try! testConstructUrlApiRequest(recipeForGetKeyCommand(command: "getSymmetricKey"))!

    static var diceKeyMemoryStoreWithKey = DiceKeyMemoryStore(DiceKey.createFromRandom())

    static var previews: some View {
        let _ = BackgroundCalculationOfApiRequestResult.precalculateForTestUseOnly(request: testRequestForPassword, seedString: diceKeyMemoryStoreWithKey.diceKeyLoaded!.toSeed())
        let _ = BackgroundCalculationOfApiRequestResult.precalculateForTestUseOnly(request: testRequestForSecret, seedString: diceKeyMemoryStoreWithKey.diceKeyLoaded!.toSeed())
        let _ = BackgroundCalculationOfApiRequestResult.precalculateForTestUseOnly(request: testRequestForSymmetricKey, seedString: diceKeyMemoryStoreWithKey.diceKeyLoaded!.toSeed())

        ApiRequestView(
            request: $testRequestForSymmetricKey,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()
        

        ApiRequestView(
            request: $testRequestForSecret,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()
        
        ApiRequestView(
            request: $testRequestForPassword,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()

        ApiRequestView(
            request: $testRequestForPassword,
            diceKeyMemoryStore: DiceKeyMemoryStore()
        ).previewLayoutMinSupported()
    }
}

