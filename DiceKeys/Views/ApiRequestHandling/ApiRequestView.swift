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

private func describeApproval(_ request: ApiRequest) -> String {
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
//    @Binding var request: ApiRequest
    @State var request: ApiRequest
    @ObservedObject var diceKeyMemoryStore: DiceKeyMemoryStore
    
    @State var userAskedToLoadDiceKey: Bool = false
    
    var diceKeyLoaded: DiceKey? {
        get { diceKeyMemoryStore.diceKeyLoaded }
    }
    
    var diceKeyAbsent: Bool { diceKeyLoaded == nil }
    var showLoadDiceKey: Bool { diceKeyAbsent && userAskedToLoadDiceKey }
    
    var apiResult: Result<SuccessResponse, Error> {
        guard let diceKey = diceKeyLoaded else { return .failure(BackgroundCalculationError.inProgress) }
        return BackgroundCalculationOfApiRequestResult.get(request: request, seedString: diceKey.toSeed() ).result
    }
    
    var successResponse: SuccessResponse? {
        guard case let .success(response) = apiResult else { return nil }
        return response
    }
    
    var error: Error? {
        guard case let .failure(error) = apiResult, case BackgroundCalculationError.inProgress = error else { return nil }
        return error
    }
    
    var mayApprove: Bool {
        successResponse != nil
    }
    var failed: Bool { error != nil }
        
    func approveRequest() {
        if let successResponse = successResponse {
            ApiRequestState.singleton.completeApiRequest(.success(successResponse))
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
                ApiRequestResultPreviewView(request: $request, diceKey: diceKey)
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
                Button(action: { self.approveRequest() }, label: { Text(describeApproval(request)) }).showIf( mayApprove)
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
//        let _ = BackgroundCalculationOfApiRequestResult.precalculateForTestUseOnly(request: testRequestForPassword, seedString: diceKeyMemoryStoreWithKey.diceKeyLoaded!.toSeed())
//        let _ = BackgroundCalculationOfApiRequestResult.precalculateForTestUseOnly(request: testRequestForSecret, seedString: diceKeyMemoryStoreWithKey.diceKeyLoaded!.toSeed())
//        let _ = BackgroundCalculationOfApiRequestResult.precalculateForTestUseOnly(request: testRequestForSymmetricKey, seedString: diceKeyMemoryStoreWithKey.diceKeyLoaded!.toSeed())

        ApiRequestView(
            request: testRequestForSymmetricKey,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()
        

        ApiRequestView(
            request: testRequestForSecret,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()
        
        ApiRequestView(
            request: testRequestForPassword,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()

        ApiRequestView(
            request: testRequestForPassword,
            diceKeyMemoryStore: DiceKeyMemoryStore()
        ).previewLayoutMinSupported()
    }
}

