//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct KnownDiceKeyCard: View {
    let diceKeyState: DiceKeyState

    var body: some View {
        Text(diceKeyState.nickname)
        if diceKeyState.isDiceKeyStored {
            Button(action: {}, label: {
                Text("Open")
            })
        }
    }
}

struct AppMainView: View {
    // Note: Navigation bar styling is controlled by the UINavigationBarController
    // extension in the Extensions directory

    @State var diceKey: DiceKey?
    @State var diceKeyState: DiceKeyState?

    var knownDiceKeysState: [DiceKeyState] {
        GlobalState.instance.knownDiceKeys.map { DiceKeyState(forKeyId: $0) }
    }

    var body: some View {
        if let diceKeyState = self.diceKeyState, let diceKey = self.diceKey {
            DiceKeyPresent(diceKey: diceKey, diceKeyState: diceKeyState, onForget: {
                self.diceKey = nil
                self.diceKeyState = nil
            })
        } else {
        NavigationView {
            VStack {
                Spacer()
                ForEach(knownDiceKeysState) { diceKeyState in
                    Text(diceKeyState.nickname)
                    if diceKeyState.isDiceKeyStored {
                        Button(action: {
                            EncryptedDiceKeyFileAccessor.instance.getDiceKey(fromKeyId: diceKeyState.id) { result in
                                    switch result {
                                    case .success(let diceKey):
                                        self.diceKey = diceKey
                                        self.diceKeyState = DiceKeyState(diceKey)
                                    default: ()
                                }
                            }
                        }, label: {
                            Text("Open")
                        })
                    }
                    Spacer()
                }
                NavigationLink(
                    destination: AssemblyInstructions(onSuccess: { self.diceKeyState = DiceKeyState($0) })) {
                    Text("Assembly Instructions")
                }
                if let diceKey = self.diceKey {
                    Spacer()
                    DiceKeyView(diceKey: diceKey, showLidTab: false)
                }
                Spacer()
                NavigationLink(
                    destination: ScanDiceKey(
                        onDiceKeyRead: { diceKey in
                            self.diceKey = diceKey
                            self.diceKeyState = DiceKeyState(diceKey)
                            print("Read diceKey with first letter \(diceKey.faces[0].letter.rawValue)")
                        })
                ) {
                Text("Scan DiceKey")
                }
                Spacer()
            }
            //.navigationTitle("DiceKeys")
            .navigationBarHidden(true)
        }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
    }
}
