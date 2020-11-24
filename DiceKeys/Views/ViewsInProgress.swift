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
            Image("ShakeTheBag").resizable().aspectRatio(1, contentMode: .fit)
            Spacer()
        }
    }
}

private struct DropDice: View {
    var body: some View {
        VStack {
            Text("Randomize it")
            Text("Don't criticize it")
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
            HStack{
                Spacer()
                switch step {
                case .Randomize:
                    Randomize()
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
        AssemblyInstructions(step: .Randomize)
        
        DiceKeyPresent(diceKey: DiceKey.createFromRandom())
    }
}
