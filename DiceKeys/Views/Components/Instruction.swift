//
//  Instruction.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/05.
//

import SwiftUI

struct Instruction: View {
    let instruction: String

    init (_ instruction: String) {
        self.instruction = instruction
    }

    var body: some View {
        HStack {
            Text(instruction).multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                .font(.largeTitle)
            Spacer()
        }
    }
}

struct Instruction_Previews: PreviewProvider {
    static var previews: some View {
        Instruction("Help me")
    }
}
