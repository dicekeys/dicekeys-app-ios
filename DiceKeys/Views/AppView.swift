//
//  AppView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/23.
//

import SwiftUI

struct TestView: View {
    @State var diceKey: DiceKey?

    var body: some View {
        VStack {
            if let diceKey = self.diceKey {
                DiceKeyView(diceKey: diceKey, viewSize: CGSize(width: 720, height: 720), showLidTab: false)
            } else {
                DiceKeysCameraView(
                    onDiceKeyRead: { diceKey in
                        self.diceKey = diceKey
                        print("Read diceKey with first letter \(diceKey.faces[0].letter.rawValue)")
                    }
                )
            }
        }
    }
}

@main
struct AppView: App {
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}
