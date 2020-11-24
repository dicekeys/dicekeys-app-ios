//
//  ViewsInProgress.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct DiceKeyPresent: View {
    let diceKey: DiceKey

    var body: some View {
        DiceKeyView(diceKey: diceKey, showLidTab: true)
    }
}

struct DiceKeyPresentPreview: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

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
        AssemblyInstructions(step: .DropDice)
        
        DiceKeyPresent(diceKey: DiceKey.createFromRandom())
    }
}
