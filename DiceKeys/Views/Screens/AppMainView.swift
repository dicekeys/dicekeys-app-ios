//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
    @ObservedObject var globalState = GlobalState.instance
    @ObservedObject var knownDiceKeysStore = KnownDiceKeysStore.singleton

    var knownDiceKeysState: [KnownDiceKeyState] {
        knownDiceKeysStore.knownDiceKeys.map { keyId in KnownDiceKeyState.forKeyId(keyId) }.filter {
            $0.isDiceKeySaved
        }
    }
    
    func showLoadDiceKey() {
        globalState.topLevelNavigation = .loadDiceKey
    }
    
    func showAssemblyInstructions() {
        globalState.topLevelNavigation = .assemblyInstructions
    }
    
    #if os(iOS)
    let screenShorterSide = UIScreen.main.bounds.size.shorterSide
    let screenHeight = UIScreen.main.bounds.size.height
    #else
    let screenShorterSide:CGFloat = NSScreen.main!.frame.height / 5.0// NSApplication.shared.windows[0].frame.height
    let screenHeight:CGFloat = NSScreen.main!.frame.height / 5.0 // NSApplication.shared.windows[0].frame.height
    #endif

    var body: some View {
        switch globalState.topLevelNavigation {
        case .loadDiceKey:
            LoadDiceKey(
                onDiceKeyLoaded: { diceKey, _ in
                    globalState.diceKeyLoaded = diceKey
                    globalState.topLevelNavigation = .diceKeyPresent
            })
        case .diceKeyPresent:
            if let unlockedDiceKeyState = globalState.diceKeyState {
                DiceKeyPresent(diceKeyState: unlockedDiceKeyState, onForget: { globalState.diceKeyLoaded = nil })
            }
        case .assemblyInstructions:
            AssemblyInstructions(onSuccess: {
                globalState.diceKeyLoaded = $0
                globalState.topLevelNavigation = .diceKeyPresent
            })
        case .nowhere:
            let view = VStack {
            Spacer()
            ForEach(knownDiceKeysState) { knownDiceKeyState in
                Button(action: {
                    EncryptedDiceKeyFileAccessor.instance.getDiceKey(fromKeyId: knownDiceKeyState.id, centerFace: knownDiceKeyState.centerFace) { result in
                            switch result {
                            case .success(let diceKey):
                                globalState.diceKeyLoaded = diceKey
                                globalState.topLevelNavigation = .diceKeyPresent
                            default: ()
                        }
                    }
                }, label: {
                    VStack {
                        if let centerFace = knownDiceKeyState.centerFace {
                            HStack {
                                Spacer()
                                DiceKeyCenterFaceOnlyView(centerFace: centerFace)
                                Spacer()
                            }.frame(
                                maxHeight: screenHeight / 5
                            )
                        }
                        Text("Unlock " + knownDiceKeyState.nickname).font(.title2)
                    }
                }).buttonStyle(PlainButtonStyle())
                Spacer()
            }
            Button(action: { showLoadDiceKey() }) {
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        Image("Scanning a DiceKey PNG")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Spacer()
                    }
//                        .frame(maxHeight: 0.3 * screenShorterSide)
                    Text("Load your DiceKey").font(.title2)
                }
                .aspectRatio(3.0, contentMode: .fit)
            }.buttonStyle(PlainButtonStyle())
            Spacer()
            Button(action: { showAssemblyInstructions() } ) {
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
            view.frame(width: 480, height: 700)
            #else
            view
            #endif
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
}
