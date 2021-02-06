//
//  ApiRequestView.swift
//  DiceKeys (iOS)
//
//  Created by Stuart Schechter on 2021/02/06.
//

import SwiftUI

struct RequestDescription: View {
    let request: ApiRequest
    
    var body: some View {
        if request is ApiRequestGetSecret {
            Text("FIXME")
        }
        Text("\(request.securityContext.host)")
    }
    
}

struct ApiRequestView: View {
    let request: ApiRequest
    @ObservedObject var globalState: GlobalState
    
    @State var userAskedToLoadDiceKey: Bool = false
    
    var diceKeyLoaded: DiceKey? {
        globalState.diceKeyLoaded
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
                    globalState.diceKeyLoaded = diceKey
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
            request: try! testConstructUrlApiRequest(testUrlForSecret)!, globalState: GlobalState()
        )
    }
}

