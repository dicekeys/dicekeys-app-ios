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

private struct Instruction: View {
    let instruction: String

    init (_ instruction: String) {
        self.instruction = instruction
    }

    var body: some View {
        HStack {
            Spacer()
            Text(instruction)
                .font(.largeTitle)
            Spacer()
        }
    }
}

private struct InstructionNote: View {
    let instruction: String

    init (_ instruction: String) {
        self.instruction = instruction
    }

    var body: some View {
        HStack {
            Spacer()
            Text(instruction)
                .font(.headline)
            Spacer()
        }
    }
}

struct SafeAreaHeader: View {
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Color.gray
            }.frame(height: geometry.safeAreaInsets.top).aspectRatio(contentMode: ContentMode.fit)
        }
    }
}

struct SafeAreaFooter: View {
    let color: Color = Color.gray

    var body: some View {
        GeometryReader { geometry in
            color.frame(
                width: geometry.size.width,
                height: geometry.safeAreaInsets.bottom
            )
        }
    }
}

private let warningBackgroundColor: Color = Color(hex: "E0585B")

private struct Warning: View {
    let message: String

    var body: some View {
        HStack {
            Spacer()
            Text(message.uppercased()).bold()
                .scaledToFill()
                .lineLimit(1)
            Spacer()
        }
    }
}

private struct Randomize: View {
    var body: some View {
        Instruction("Shake the dice in the felt bag or in your hands.")
        Spacer()
        Image("Illustration of shaking bag").resizable().aspectRatio(1, contentMode: .fit)
    }
}

private struct DropDice: View {
    var body: some View {
        Instruction("Let the dice fall randomly.")
        Spacer()
        Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
        Spacer()
        Instruction("Most should land squarely into the 25 slots in the box base.")
    }
}

private struct FillEmptySlots: View {
    var body: some View {
        Instruction("Put the remaining dice squarely into the empty slots.")
        Spacer()
        Image("Box Bottom All Dice In Place").resizable().aspectRatio(contentMode: .fit)
        Spacer()
        Instruction("Leave their rest in their original random order and orientations.")
    }
}

private struct ScanFirstTime: View {
    @State var scanning: Bool = false
    @Binding var diceKey: DiceKey?

    var body: some View {
        Instruction("Scan the dice in the bottom of the box (without the top.)")
        Spacer()
        if let diceKey = self.diceKey {
            DiceKeyView(diceKey: diceKey)
            Button("Scan again") { self.diceKey = nil; self.scanning = true }
        } else if scanning {
            ScanDiceKey { self.diceKey = $0; self.scanning=false }
            Spacer()
            Button("Cancel") { self.scanning = false }
        } else {
            Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit)
            Spacer()
            Button("Scan now") { self.scanning = true }
        }
    }
}

private struct CreateBackup: View {
    let diceKey: DiceKey?

    var body: some View {
        VStack {
            Instruction("Use Stickeys or another DiceKey kit to make a copy of the key you just created.")
            Spacer()
            if let diceKey = self.diceKey {
                BackupDiceKey(diceKey: diceKey)
            } else {
                Image("Assembling Stickeys").resizable().aspectRatio(contentMode: .fit)
            }
            Spacer()
//        InstructionNote("If you place a sticker incorrectly, you may re-arrange your dice to match the mistake and then go back to the previous step to re-scan the dice.")
//        if let diceKey = self.diceKey {
//            Spacer()
//            HStack {
//                Spacer()
//                DiceKeyView(diceKey: diceKey, showLidTab: false)
//                Spacer()
//                Text("The DiceKey you scanned in the previous step.")
//                Spacer()
//            }
//        }
        }
    }
}

private struct ValidateBackup: View {
    var body: some View {
        Text("To do")
        // ScanFirstTime()
    }
}

private struct SealBox: View {
    var body: some View {
        Instruction("Place the box top above the base so that the hinges line up.")
        Spacer()
        Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
        Spacer()
        Instruction("Press firmly down along the edges. The box will snap together, helping to prevent accidental re-opening.")
    }
}

struct StepBar: View {
    let stepCount: Int
    let currentStep: Int

    var body: some View {
        HStack {
            ForEach(1..<stepCount+1) { step in
                Spacer()
                Text("\(step)")
                    .font(.title3)
                    .modifyIf( step == currentStep ) { $0.underline().bold() }
                    .minimumScaleFactor(3)
                    .scaledToFill()
            }
            Spacer()
        }.padding(.vertical, 3).background(Color.white)
    }
}

struct AssemblyInstructions: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var onSuccess: ((DiceKey) -> Void)?

    enum Step: Int {
        case Randomize = 1
        case DropDice
        case FillEmptySlots
        case ScanFirstTime
        case CreateBackup
//        case ValidateBackup
        case SealBox
    }

    @State private var diceKeyScanned: DiceKey?
    @State private var diceKeyValidationResult: DiceKey?
    @State var step: Step = Step(rawValue: 1)!

    private let first = Step.Randomize.rawValue
    private let last = Step.SealBox.rawValue

    private var showWarning: Bool { get {
        step.rawValue > Step.Randomize.rawValue &&
        step.rawValue < Step.SealBox.rawValue
    } }

    private var showSkipButton: Bool { get {
        ( step == .ScanFirstTime && diceKeyScanned == nil )
//            ||
//        ( step == .ValidateBackup && diceKeyValidationResult == nil ) // FIXE != diceKeyScanned )
    }}

    var body: some View {
        GeometryReader { geometry in
            VStack {
//                VStack {
//                    HStack {}.frame(height: geometry.safeAreaInsets.top)
//                }
                Spacer()
                switch step {
                case .Randomize: Randomize()
                case .DropDice: DropDice()
                case .FillEmptySlots: FillEmptySlots()
                case .ScanFirstTime: ScanFirstTime(diceKey: self.$diceKeyScanned)
                case .CreateBackup: CreateBackup(diceKey: self.diceKeyScanned)
//                case .ValidateBackup: ValidateBackup()
                case .SealBox: SealBox()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button("Previous") { step = Step(rawValue: step.rawValue - 1) ?? Step.Randomize }.disabled(step.rawValue == first)
                    Spacer()
                    Button(step.rawValue == last ? "Done" : showSkipButton ? "Skip": "Next") {
                        if step.rawValue == last {
                            // exit navigation layer
                            if let diceKey = self.diceKeyScanned {
                                onSuccess?(diceKey)
                            }
                            self.presentationMode.wrappedValue.dismiss()
                        } else {
                            step = Step(rawValue: step.rawValue + 1) ?? Step.SealBox
                        }
                    }
                    Spacer()
                }.padding(.bottom, 10)
                StepBar(stepCount: last, currentStep: step.rawValue)
                VStack {
                    Warning(message: "Do not close the box before the final Step.")
                        .padding(.vertical, 5)
                    HStack {}.frame(height: geometry.safeAreaInsets.bottom)
                }.foregroundColor(.white)
                .background(warningBackgroundColor)
                .hideIf(!showWarning)
            }.edgesIgnoringSafeArea(.bottom)}
            .navigationTitle("Assembly Instructions")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AssemblyInstructions_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        CreateBackup(diceKey: DiceKey.createFromRandom())
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        AssemblyInstructions(step: .Randomize)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        AssemblyInstructions(step: .DropDice)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        AssemblyInstructions(step: .FillEmptySlots)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        AssemblyInstructions(step: .ScanFirstTime)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        AssemblyInstructions(step: .CreateBackup)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//        AssemblyInstructions(step: .ValidateBackup)
        AssemblyInstructions(step: .SealBox)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        // AssemblyInstructions()
    }
}
