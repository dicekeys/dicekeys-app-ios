//
//  ViewsInProgress.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct DiceKeyAbsent: View {
    let diceKey: DiceKey

    var body: some View {
        DiceKeyView(diceKey: DiceKey.createFromRandom(), showLidTab: true)
    }
}

struct DiceKeyAbsentPreview: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}



struct ViewsInProgress_Previews: PreviewProvider {
    static var previews: some View {
//        Funnel(height: 100, topWidth: 200, bottomWidth: 500)
//            .previewLayout(.fixed(width: 500, height: 100))

        DiceKeyFunnel(diceKeySize: 600, bottomWidth: 1000, contentHeight: 100)
            .previewLayout(.fixed(width: 1000, height: 1000))
            .background(Color.yellow)
//        AssemblyInstructions(step: .DropDice)

//        DiceKeyPresent(diceKey: DiceKey.createFromRandom())
    }
}
