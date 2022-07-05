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
    
    // FIXME  --  areRecipeSigned ? "recreate" : "create";
    var createOrRecreate: String { "create" }

    var description: String {
        request is ApiRequestGetPassword ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) a password?" :
        request is ApiRequestGetSecret ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) a secret security code?" :
        request is ApiRequestGetUnsealingKey ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) keys to encode and decode secrets?" :
        request is ApiRequestGetSymmetricKey ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) a key to encode and decode secrets?" :
        request is ApiRequestSealWithSymmetricKey ?
        "May \(request.hostOrName) use your DiceKey to encode a secret?" :
        request is ApiRequestUnsealWithSymmetricKey ?
        "May \(request.hostOrName) use your DiceKey to decode a secret?" :
        request is ApiRequestUnsealWithUnsealingKey ?
        "May \(request.hostOrName) use your DiceKey to decode a secret?" :
        // Less common
        request is ApiRequestGetSigningKey ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) keys to sign data?" :
        request is ApiRequestGenerateSignature ?
        "May \(request.hostOrName) use your DiceKey to add its digital signature to data?" :
        request is ApiRequestGetSignatureVerificationKey ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) a key used to verify data it has signed?" :
          // Uncommon
        request is ApiRequestGetSealingKey ?
        "May \(request.hostOrName) use your DiceKey to \(createOrRecreate) keys to store secrets?" :
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

/// This view display an API request, a request made by another
/// application (or website) to perform a cryptographic operation
/// or key generation with the user's DiceEey.
///
/// It gives the option for the user to cancel or continue
struct ApiRequestView: View {
    var request: ApiRequest
    @ObservedObject var diceKeyMemoryStore: DiceKeyMemoryStore
    @ObservedObject var backgroundCalculationOfApiRequestResult: BackgroundCalculationOfApiRequestResult
        @State var userAskedToLoadDiceKey: Bool = false
    
    @State private var sendCenterLetterAndDigit = true
    @State private var sequence = 1

    
    init (_ apiRequest: ApiRequest, diceKeyMemoryStore: DiceKeyMemoryStore = DiceKeyMemoryStore.singleton) {
        self.request = apiRequest
        self._diceKeyMemoryStore = ObservedObject(initialValue: diceKeyMemoryStore)
        let newBackgroundCalculationOfApiRequestResult = BackgroundCalculationOfApiRequestResult.get(request: apiRequest, sequence: 1)
        
        self._backgroundCalculationOfApiRequestResult = ObservedObject(initialValue: newBackgroundCalculationOfApiRequestResult)
        
        _ = diceKeyMemoryStore.diceKeyLoaded.publisher.sink { diceKey in
            newBackgroundCalculationOfApiRequestResult.execute(seedString: diceKey.toSeed(), sequence: 1)
        }
    }
    
    var diceKeyLoaded: DiceKey? {
        get { diceKeyMemoryStore.diceKeyLoaded }
    }
    
    var diceKeyAbsent: Bool { diceKeyLoaded == nil }
    var showLoadDiceKey: Bool { diceKeyAbsent && userAskedToLoadDiceKey }
    
    var apiResult: Result<(response: SuccessResponse, sequence: Int?, centerLetterAndDigit: String?), Error> {
        guard let diceKey = diceKeyLoaded else { return .failure(BackgroundCalculationError.inProgress) }
        
        let apiRequestResult = BackgroundCalculationOfApiRequestResult.get(request: request, seedString: diceKey.toSeed(), sequence: self.sequence)
        
        switch apiRequestResult.result {
        case .failure(let error):
            return .failure(error)
        case .success(let successResponse):
            return .success((successResponse, apiRequestResult.sequence, sendCenterLetterAndDigit ? diceKey.centerFace.letterAndDigit : nil))
        }
    }
    
    var successful: Bool {
        if case .success = apiResult { return true } else { return false }
    }
        
    var successResponse: (response: SuccessResponse, sequence: Int?, centerLetterAndDigit: String?)? {
        guard case let .success(response) = apiResult else { return nil }
        return response
    }
    
    var awaitingResult: Bool {
        if case let .failure(error) = apiResult, case BackgroundCalculationError.inProgress = error {
            return true
        } else {
            return false
        }
    }

    var error: Error? {
        guard case let .failure(error) = apiResult else { return nil }
        if case BackgroundCalculationError.inProgress = error { return nil }
        return error
    }
    
    var mayApprove: Bool {
        successResponse != nil
    }
    var failed: Bool { error != nil }
        
    func approveRequest() {
        if (!awaitingResult) {
            ApiRequestState.singleton.completeApiRequest(apiResult)
        }
    }
  
    func declineRequest() {
        ApiRequestState.singleton.completeApiRequest(.failure(RequestException.UserDeclinedToAuthorizeOperation))
    }
    
    var body: some View {
        VStack {
            RequestQuestionView(request: request)
            Spacer()
            if showLoadDiceKey {
                LoadDiceKey(onDiceKeyLoaded: { diceKey, _ in
                    diceKeyMemoryStore.setDiceKey(diceKey: diceKey)
                    userAskedToLoadDiceKey = false
                }, onBack: {
                    userAskedToLoadDiceKey = false
                })
            } else if let error = error {
                Text("There was an error computing the result of the request. It may be malformed.")
                Text("\(error.localizedDescription)")
            } else if (diceKeyLoaded != nil && awaitingResult) {
                Text("Calculating requested value.")
            } else if let diceKey = diceKeyLoaded {
                ApiRequestResultPreviewView(request: request, diceKey: diceKey, apiResultObservable: backgroundCalculationOfApiRequestResult, sequence: $sequence)
            } else {
                Text("To allow this action, you'll first need to load your DiceKey.")
                Spacer()
                SavedDiceKeysView()
                Button(action: { userAskedToLoadDiceKey = true }) {
                    VStack(alignment: .center) {
                        HStack {
                            Spacer()
                            Image("Scanning a DiceKey PNG")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            Spacer()
                        }
                        Text("Load your DiceKey").font(.title2)
                    }
                    .aspectRatio(3.0, contentMode: .fit)
                }.buttonStyle(PlainButtonStyle())
            }
            if let diceKey = diceKeyLoaded {
                Spacer()
                Stepper(value: $sequence, in: 1...9999, step: 1) {
                    Text("Sequence: \(sequence > 1 ? String(sequence) : "none")")
                }
                Spacer()
                Toggle("Reveal that the center die is **\(diceKey.centerFace.letterAndDigit)** so that **\(request.hostOrName)** can remind you next time", isOn: $sendCenterLetterAndDigit)
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: { self.declineRequest() }, label: { Text("Cancel") })
                Spacer()
                Button(action: { self.approveRequest() }, label: { Text(awaitingResult || successful ? describeApproval(request) : "Return error") }).hideIf( awaitingResult )
                Spacer()
            }
        }.padding(.all, 20)
        .onChange(of: sequence, perform: { _ in
            if let diceKey = diceKeyLoaded {
                backgroundCalculationOfApiRequestResult.execute(seedString: diceKey.toSeed(), sequence: self.sequence)
            }
        })
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
            testRequestForSymmetricKey,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()
        

        ApiRequestView(
            testRequestForSecret,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()
        
        ApiRequestView(
            testRequestForPassword,
            diceKeyMemoryStore: diceKeyMemoryStoreWithKey
        ).previewLayoutMinSupported()

        ApiRequestView(
            testRequestForPassword,
            diceKeyMemoryStore: DiceKeyMemoryStore()
        ).previewLayoutMinSupported()
    }
}

