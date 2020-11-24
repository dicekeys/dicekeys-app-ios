//
//  AssemblyInstructions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/25.
//

import SwiftUI

struct AssemblyInstructionsPreview: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

private struct Randomize: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Shake the dice in the felt bag or in your hands.").font(.largeTitle)
            Spacer()
            Image("Illustration of shaking bag").resizable().aspectRatio(1, contentMode: .fit)
            Spacer()
        }
    }
}

struct InstructionsWarning: View {
    let message: String

    static let backgroundColor: Color = Color(hex: "E0585B")

    var body: some View {
        HStack {
            Spacer()
            Text(message.uppercased()).bold()
                .scaledToFill()
                .lineLimit(1)
            Spacer()
        }.background(InstructionsWarning.backgroundColor)
    }
}

private struct DropDice: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Let the dice fall randomly.").font(.largeTitle)
            Spacer()
            Image("Box Bottom After Roll").resizable().aspectRatio(1, contentMode: .fit)
            Spacer()
            Text("Most should land squarely into the 25 slots in the box base.").font(.largeTitle)
            Spacer()
            InstructionsWarning(message: "Do not close the box before The final Step.")
        }
    }
}

private struct FillEmptySlots: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Put the remaining dice squarely into the empty slots.").font(.largeTitle)
            Spacer()
            Image("Box Bottom All Dice In Place").resizable().aspectRatio(1, contentMode: .fit)
            Spacer()
            Text("Leave their rest in their original random order and orientations.").font(.largeTitle)
            Spacer()
            InstructionsWarning(message: "Do not close the box before The final Step.")
        }
    }
}

struct AssemblyInstructions: View {
    enum Step: Int {
        case Randomize = 1
        case DropDice
        case FillEmptySlots
        case ScanFirstTime
        case CreateBackup
        case ValidateBackup
        case SealBox
    }

    let first = Step.Randomize.rawValue
    let last = Step.SealBox.rawValue

    @State var step: Step = Step(rawValue: 1)!

    var body: some View {
        VStack {
            HStack {
                ForEach(first..<last) { step in
                    Spacer()
                    Text("\(step)").fontWeight(step == self.step.rawValue ? .bold : .none)
                }
                Spacer()
            }.background(Color.gray)
            Spacer()
            HStack {
                Spacer()
                switch step {
                case .Randomize: Randomize()
                case .DropDice: DropDice()
                case .FillEmptySlots: FillEmptySlots()
                default:
                    EmptyView()
                }
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Button("Previous") { step = Step(rawValue: step.rawValue - 1) ?? Step.Randomize }.disabled(step.rawValue == first)
                Spacer()
                if step.rawValue < last {
                    Button("Next") { step = Step(rawValue: step.rawValue + 1) ?? Step.SealBox }
                }
                Spacer()
            }
        }
    }
}

struct AssemblyInstructions_Previews: PreviewProvider {
    static var previews: some View {
        AssemblyInstructions()
    }
}
