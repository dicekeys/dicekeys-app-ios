//
//  ViewsInProgress.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

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
