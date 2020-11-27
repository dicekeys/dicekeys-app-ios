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
    @State var diceKey: DiceKey?

    var body: some View {
        NavigationView {
            VStack {
//                if let diceKey = self.diceKey {
//                    DiceKeyPresent(diceKey: diceKey)
//                } else {
                    Spacer()
                    NavigationLink(
                        destination: AssemblyInstructions(onSuccess: { self.diceKey = $0 })) {
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
                                print("Read diceKey with first letter \(diceKey.faces[0].letter.rawValue)")
                            })
                    ) {
                    Text("Scan DiceKey")
                    }
//                }
                Spacer()
            }
//            Text("This is odd")
        }.navigationViewStyle(StackNavigationViewStyle())//.navigationBarTitle("DiceKeys Home")
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView()
    }
}
