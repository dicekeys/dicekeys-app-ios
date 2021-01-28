//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
//    @State var diceKey: DiceKey?
    @ObservedObject var globalState = GlobalState.instance
//    @ObservedObject var diceKeyState = UnlockedDiceKeyState(diceKey: nil)
    @State var showAssembleInstructions = false

    var knownDiceKeysState: [KnownDiceKeyState] {
        GlobalState.instance.knownDiceKeys.map { keyId in KnownDiceKeyState.forKeyId(keyId) }.filter {
            $0.isDiceKeySaved
        }
    }

//    var hiddenNavigationLinkToScanDiceKey: some View {
//
//        return NavigationLink(
//            destination: LoadDiceKey(
//                onDiceKeyLoaded: { diceKey, _ in
//                    globalState.diceKeyLoaded = diceKey
//                    scanDiceKeyIsActive = false
//                }),
//            isActive: $scanDiceKeyIsActive,
//            label: { EmptyView() }
//        )
//        .frame(width: 0, height: 0)
//        .position(x: 0, y: 0)
//        .hidden()
//    }
//
//    var hiddenNavigationLinkToDiceKeyPresent: some View {
//        NavigationLink(
//            destination: DiceKeyPresent(diceKeyState: globalState.diceKeyState!,
////                diceKey: Binding<DiceKey>(
////                    get: { self.diceKey ?? DiceKey.Example },
////                    set: { self.diceKey = $0 }
////                ),
//                onForget: {
//                    if let diceKey = globalState.diceKeyLoaded {
//                        globalState.diceKeyLoaded = nil
//                        UnlockedDiceKeyState.forget(diceKey: diceKey)
//                    }
//                }
//            ),
//            isActive: Binding<Bool>(
//                get: { globalState.diceKeyLoaded != nil },
//                set: { _ in }
//            ),
//            label: { EmptyView() }
//        )
//        .frame(width: 0, height: 0)
//        .position(x: 0, y: 0)
//        .hidden()
//    }
    
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
            VStack {
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
                })
                Spacer()
            }
            VStack(alignment: .center) {
                KeyScanningIllustration(.Dice).aspectRatio(contentMode: .fit).frame(maxHeight: 0.3 * screenShorterSide)
                    .onTapGesture{ showLoadDiceKey() }
                Button(action: { showLoadDiceKey() }) {
                        Text("Load your DiceKey").font(.title2)
                }
            }
            Spacer()
                HStack {
                    Spacer()
                    Image("Illustration of shaking bag").resizable().aspectRatio(contentMode: .fit)
                    Spacer(minLength: 20)
                    Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
                    Spacer(minLength: 20)
                    Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
                    Spacer(minLength: 20)
                }.padding(.horizontal, 20).frame(maxHeight: screenShorterSide / 4)
                .onTapGesture { showAssemblyInstructions() }
                Button(action: { showAssemblyInstructions() } ) {
                VStack {
                    Text("Assemble your First DiceKey").font(.title2)
                }
            }
            Spacer()
        }
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
        #else
        AppMainView().frame(width: 720, height: 600)
        #endif
    }
    }
}
