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
    @ObservedObject var globalState: GlobalState = GlobalState.instance
    @State var userAskedToLoadDiceKey: Bool = false
    
    var apiRequestWithCompletionCallback: ApiRequestWithCompletionCallback? {
        globalState.requestForUserToApprove
    }
    
    var diceKeyLoaded: DiceKey? {
        globalState.diceKeyLoaded
    }
    
    var diceKeyAbsent: Bool { diceKeyLoaded == nil }
    var showLoadDiceKey: Bool { diceKeyAbsent && userAskedToLoadDiceKey }
    
    var request: ApiRequest? { apiRequestWithCompletionCallback?.request }
        
    func approveRequest() {
        if let diceKey = diceKeyLoaded {
            globalState.completeApiRequest(.success(diceKey.toSeed()))
        }
    }
  
    func declineRequest() {
        globalState.completeApiRequest(.failure(RequestException.UserDeclinedToAuthorizeOperation))
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
    static var previews: some View {
        ApiRequestView()
    }
}

