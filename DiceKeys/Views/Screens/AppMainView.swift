//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
    // Note: Navigation bar styling is controlled by the UINavigationBarController
    // extension in the Extensions directory

//    @State var diceKey: DiceKey?
    @State var diceKey: DiceKey?
//    @State var diceKeyState: UnlockedDiceKeyState?

    var knownDiceKeysState: [KnownDiceKeyState] {
        GlobalState.instance.knownDiceKeys.map { KnownDiceKeyState($0) }.filter { $0.isDiceKeyStored }
    }
    
    var body: some View {
        if let diceKey: DiceKey = self.diceKey {
            DiceKeyPresent(
                diceKey: Binding<DiceKey>(
                    get: { self.diceKey ?? DiceKey.Example },
                    set: { self.diceKey = $0 }
                ),
                onForget: {
                    UnlockedDiceKeyState.forget(diceKey: diceKey)
                    self.diceKey = nil
                }
            )
        } else {
        NavigationView {
            VStack {
                Spacer()
                ForEach(knownDiceKeysState) { knownDiceKeyState in
                    Button(action: {
                        EncryptedDiceKeyFileAccessor.instance.getDiceKey(fromKeyId: knownDiceKeyState.id) { result in
                                switch result {
                                case .success(let diceKey):
                                    self.diceKey = diceKey
                                default: ()
                            }
                        }
                    }, label: {
                        VStack {
                            if let centerFace = knownDiceKeyState.centerFace {
                                DieView(face: centerFace, dieSize: UIScreen.main.bounds.size.shorterSide / 5, faceBorderColor: Color.gray)
                            }
                            Text("Unlock " + knownDiceKeyState.nickname).font(.title2)
                        }
                    })
                    Spacer()
                }
                NavigationLink(
                    destination: ScanDiceKey(
                        onDiceKeyRead: { diceKey in
                            self.diceKey = diceKey
                        })
                ) {
                    VStack {
                        Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: UIScreen.main.bounds.size.shorterSide / 4)
                        Text("Read your DiceKey").font(.title2)
                    }
                }
                Spacer()
                NavigationLink(
                    destination: AssemblyInstructions(onSuccess: { self.diceKey = $0 })) {
                    VStack {
                        HStack {
                            Spacer()
                            Image("Illustration of shaking bag").resizable().aspectRatio(contentMode: .fit)
                            Spacer(minLength: 20)
                            Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
                            Spacer(minLength: 20)
                            Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
                            Spacer(minLength: 20)
                        }.padding(.horizontal, 20).frame(maxHeight: UIScreen.main.bounds.size.shorterSide / 4)
                        Text("Assemble your First DiceKey").font(.title2)
                    }
                }
                if let diceKey = self.diceKey {
                    Spacer()
                    DiceKeyView(diceKey: diceKey, showLidTab: false)
                }
                Spacer()
            }
            //.navigationTitle("DiceKeys")
            .navigationBarTitleDisplayMode(.inline)
            //.navigationBarHidden(true)
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
