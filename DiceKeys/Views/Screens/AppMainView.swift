//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct KnownDiceKeys: View {
    var body: some View {
        Text("Known DiceKeys will go here")
    }
}

struct AppMainView: View {
    @State var diceKeyState: DiceKeyState?

    var body: some View {
        if let diceKeyState = self.diceKeyState {
            DiceKeyPresent(diceKeyState: diceKeyState, onForget: {
                self.diceKeyState = nil
            })
        } else {
        NavigationView {
            VStack {
//                if let diceKey = self.diceKey {
//                    DiceKeyPresent(diceKey: diceKey)
//                } else {
                    Spacer()
                    NavigationLink(
                        destination: AssemblyInstructions(onSuccess: { self.diceKeyState = DiceKeyState($0) })) {
                        Text("Assembly Instructions")
                    }
                    if let diceKey = self.diceKeyState?.diceKey {
                        Spacer()
                        DiceKeyView(diceKey: diceKey, showLidTab: false)
                    }
                    Spacer()
                    NavigationLink(
                        destination: ScanDiceKey(
                            onDiceKeyRead: { diceKey in
                                self.diceKeyState = DiceKeyState(diceKey)
                                print("Read diceKey with first letter \(diceKey.faces[0].letter.rawValue)")
                            })
                    ) {
                    Text("Scan DiceKey")
                    }
//                }
                Spacer()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
