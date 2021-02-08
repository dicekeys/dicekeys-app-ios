//
//  ApiRequestView.swift
//  DiceKeys (iOS)
//
//  Created by Stuart Schechter on 2021/02/06.
//

import SwiftUI


struct RequestDescription: View {
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
    
    // FIXME  --  areDerivationOptionsSigned ? "recreate" : "create";
    var createOrRecreate: String { "create" }

    var description: String {
        request is ApiRequestGetPassword ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) a password?" :
        request is ApiRequestGetSecret ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) a secret security code?" :
        request is ApiRequestGetUnsealingKey ?
          "May \(hostComponent) use your DiceKey to \(createOrRecreate) keys to encode and decode secrets?" :
        request is ApiRequestGetSymmetricKey ?
          "May \(hostComponent) use your DiceKey to a \(createOrRecreate) key to encode and decode secrets?" :
        request is ApiRequestSealWithSymmetricKey ?
          "May \(hostComponent) use your DiceKey to encode a secret?" :
        request is ApiRequestUnsealWithSymmetricKey ?
          "May \(hostComponent) use your DiceKey to allow to decode a secret?" :
        request is ApiRequestUnsealWithUnsealingKey ?
          "May \(hostComponent) use your DiceKey to allow to decode a secret?" :
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
            .minimumScaleFactor(0.2)
            .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
    }
    
}

struct ApiRequestView: View {
    let request: ApiRequest
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
    
    var requestDescription: some View {
        Text("FIXME")
    }
    
    var responsePreview: some View {
        Text("FIXME")
    }
    
    var body: some View {
        VStack {
            Spacer()
            if let request = self.request {
                RequestDescription(request: request)
            }
            Spacer()
            if showLoadDiceKey {
                LoadDiceKey(onDiceKeyLoaded: { diceKey, _ in
                    diceKeyMemoryStore.setDiceKey(diceKey: diceKey)
                    userAskedToLoadDiceKey = false
                }, onBack: {
                    userAskedToLoadDiceKey = false
                })
            } else if diceKeyAbsent {
                VStack {
                    Text("To allow this action, you'll first need to load your DiceKey.")
                    Button(action: { userAskedToLoadDiceKey = true }, label: { Text("Load DiceKey") })
                }
            } else {
                responsePreview
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: { self.declineRequest() }, label: { Text("Cancel") })
                Spacer()
                Button(action: { self.declineRequest() }, label: { Text("Approve") }).hideIf(diceKeyAbsent)
                Spacer()
            }
            Spacer()
        }
    }
}

struct ApiRequestView_Previews: PreviewProvider {
    static let testUrlForSecret = "https://dicekeys.app/?command=getPassword&requestId=1&respondTo=https%3A%2F%2Fpwmgr.app%2F--derived-secret-api--%2F&derivationOptionsJson=%7B%22allow%22%3A%5B%7B%22host%22%3A%22pwmgr.app%22%7D%5D%7D&derivationOptionsJsonMayBeModified=false"
    
    static var previews: some View {
        ApiRequestView(
            request: try! testConstructUrlApiRequest(testUrlForSecret)!,
            diceKeyMemoryStore: DiceKeyMemoryStore()
        )
        
        
        ApiRequestView(
            request: try! testConstructUrlApiRequest(testUrlForSecret)!,
            diceKeyMemoryStore: DiceKeyMemoryStore(DiceKey.createFromRandom())
        )
    }
}

