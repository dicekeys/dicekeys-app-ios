//
//  DiceKeyPresent.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/27.
//

import SwiftUI

struct DiceKeyPresent: View {
    let diceKey: DiceKey

    var body: some View {
        DiceKeyView(diceKey: diceKey, showLidTab: true)
    }
}

struct DiceKeyPresent_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyPresent(diceKey: DiceKey.createFromRandom())
    }
}
