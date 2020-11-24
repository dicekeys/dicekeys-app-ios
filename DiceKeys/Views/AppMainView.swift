//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
    @State var diceKey: DiceKey?

    var body: some View {
        VStack {
            NavigationView {
                VStack {
                    if let diceKey = self.diceKey {
                        DiceKeyPresent(diceKey: diceKey)
                    } else {
                        NavigationLink(
                            destination: ScanDiceKey(
                                onDiceKeyRead: { diceKey in
                                    self.diceKey = diceKey
                                    print("Read diceKey with first letter \(diceKey.faces[0].letter.rawValue)")
                                })
                        ) {
                        Text("Scan DiceKey")
                        }
                    }
                }.navigationBarTitle("DiceKeys")
            }
        }
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView()
    }
}
