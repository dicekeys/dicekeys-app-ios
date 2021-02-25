//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
    @StateObject var knownDiceKeysStore = KnownDiceKeysStore.singleton
    @StateObject var navigationState = WindowNavigationState()
    @StateObject var diceKeyMemoryStore = DiceKeyMemoryStore.singleton
    @StateObject var requestState = ApiRequestState.singleton
    @State var showSave: Bool = false

    var knownDiceKeysState: [StoredEncryptedDiceKeyMetadata] {
        knownDiceKeysStore.knownDiceKeys.map { keyId in StoredEncryptedDiceKeyMetadata.forKeyId(keyId) }.filter {
            $0.isDiceKeyStored
        }
    }
    
    func diceKeyLoaded(_ diceKey: DiceKey) {
        diceKeyMemoryStore.setDiceKey(diceKey: diceKey)
        navigationState.showLoadDiceKey = false
    }
    
    func diceKeyRemove() {
        diceKeyMemoryStore.clearForegroundDiceKey()
    }
    
    var mainPageView: some View {
        // Main page view
        let view = VStack {
            Spacer()
            SavedDiceKeysView(saveCallback: { diceKey in
                self.showSave = true
                diceKeyMemoryStore.setDiceKey(diceKey: diceKey)
            })
            Button(action: { navigationState.showLoadDiceKey = true }) {
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
            Spacer()
            Button(action: { navigationState.showAssemblyInstructions = true } ) {
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        Image("Illustration of shaking bag")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Spacer(minLength: 10)
                        Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
                        Spacer(minLength: 10)
                        Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
                        Spacer(minLength: 10)
                    }
                    .aspectRatio(4, contentMode: .fit)
                    //.frame(maxHeight: screenShorterSide / 2)
                    Text("Assemble \(knownDiceKeysState.count == 0 ? "your First" : "a") DiceKey").font(.title2)
                }
            }.buttonStyle(PlainButtonStyle())
            Spacer()
        }
        #if os(macOS)
        return view.frame(width: 480, height: 700)
        #else
        return view
        #endif
    }
    
    var body: some View {
        if let requestForUserToApprove = requestState.requestForUserToApprove {
            ApiRequestView(requestForUserToApprove, diceKeyMemoryStore: diceKeyMemoryStore)
        } else if (navigationState.showLoadDiceKey) {
            LoadDiceKey(
                onDiceKeyLoaded: { diceKey, _ in
                    diceKeyLoaded(diceKey)
                },
                onBack: { navigationState.showLoadDiceKey = false }
            )
        } else if (navigationState.showAssemblyInstructions) {
            AssemblyInstructions(onSuccess: { diceKey in
                diceKeyLoaded(diceKey)
                navigationState.showAssemblyInstructions = false
            }, onBack: {
                navigationState.showAssemblyInstructions = false
            })
        } else if let unlockedDiceKeyState = diceKeyMemoryStore.diceKeyState {
            DiceKeyPresent(
                diceKeyState: unlockedDiceKeyState,
                onComplete: {
                    self.showSave = false
                    diceKeyMemoryStore.clearForegroundDiceKey()
                },
                pageContent: self.showSave ? .Save : .Default
            )
        } else {
            mainPageView
        }
    }
}

struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
//        AppMainView().previewLayout(.fixed(width: 2048, height: 2732))
        #else
        AppMainView()
        #endif
    }
}
