//
//  Instruction.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/05.
//

import SwiftUI

struct Instruction: View {
    let instruction: String
    let lineLimit: Int?

    init (_ instruction: String, lineLimit: Int? = nil) {
        self.instruction = instruction
        self.lineLimit = lineLimit
    }

    var body: some View {
        HStack {
            Text(instruction)
                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                .font(.largeTitle)
                .lineLimit(self.lineLimit)
                .minimumScaleFactor(0.5)
            Spacer()
        }
    }
}

struct Instruction_Previews: PreviewProvider {
    static var previews: some View {
        Instruction("Help me")
    }
}
