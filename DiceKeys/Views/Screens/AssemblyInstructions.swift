//
//  AssemblyInstructions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/25.
//

import SwiftUI

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

struct SingleLineScaledText: View {
    let text: String

    init (_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text).font(Font.system(size: 500, weight: Font.Weight.bold))
        .minimumScaleFactor(0.01)
        .scaledToFit()
        .lineLimit(1)
    }
}

private struct Warning: View {
    let message: String

    var body: some View {
        HStack {
            Spacer()
            Text(message.uppercased()).bold()
                .minimumScaleFactor(0.01)
                .scaledToFit()
                .lineLimit(1)
            Spacer()
        }
    }
}

private struct Randomize: View {
    var body: some View {
        Instruction("Shake the dice in the felt bag or in your hands.")
        Spacer()
        Image("Illustration of shaking bag").resizable().aspectRatio(contentMode: .fit)
        Spacer()
    }
}

private struct DropDice: View {
    var body: some View {
        Instruction("Let the dice fall randomly.")
        Spacer()
        Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
        Spacer()
        Instruction("Most should land squarely into the 25 slots in the box base.")
        Spacer()
    }
}

private struct FillEmptySlots: View {
    var body: some View {
        Instruction("Put the remaining dice squarely into the empty slots.")
        Spacer()
        Image("Box Bottom All Dice In Place").resizable().aspectRatio(contentMode: .fit)
        Spacer()
        Instruction("Leave the rest in their original random order and orientations.")
        Spacer()
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
            RoundedTextButton("Scan again") { self.diceKey = nil; self.scanning = true }
        } else if scanning {
            ScanDiceKey { self.diceKey = $0; self.scanning = false }
            Spacer()
            RoundedTextButton("Cancel") { self.scanning = false }
        } else {
            Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).offset(x: 0, y: -50)
            RoundedTextButton("Scan") { self.scanning = true }
        }
        Spacer()
    }
}

private struct SealBox: View {
    var body: some View {
        Instruction("Place the box top above the base so that the hinges line up.")
        Spacer()
        Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
        Spacer()
        Instruction("Press firmly down along the edges. The box will snap together, helping to prevent accidental re-opening.")
        Spacer()
    }
}

private struct InstructionsDone: View {
    let createdDiceKey: Bool
    let backedUpSuccessfully: Bool

    var body: some View {
        SingleLineScaledText(createdDiceKey ? "You did it!" : "That's it!")
        Spacer()
        if !createdDiceKey {
            Instruction("There's nothing more to it.")
            Spacer()
            Instruction("Go back to assemble and scan in a real DiceKey.").padding(.top, 5)
            Spacer()
        } else if !backedUpSuccessfully {
            Instruction("Be sure to make a backup soon!")
            Spacer()
        }
        if createdDiceKey {
            Instruction("When you press the \"Done\" button, we'll take you to the same screen you'll see after scanning your DiceKey from the home screen.")
            Spacer()
        }
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
        case Done
    }

    @State private var diceKeyScanned: DiceKey?
    @State private var backupScanned: DiceKey?
    @State var step: Step = Step(rawValue: 1)!

    @StateObject var backupDiceKeyState = BackupDiceKeyState(target: .Stickeys)

    @State var userChoseToAllowSkipScanningStep: Bool = false
    @State var userChoseToAllowSkippingBackupStep: Bool = false

    private let first = Step.Randomize.rawValue
    private let last = Step.Done.rawValue

    var backupSuccessful: Bool {
        DiceKey.rotationIndependentEquals(diceKeyScanned, backupScanned)
    }

    private var showWarning: Bool { get {
        step.rawValue > Step.Randomize.rawValue &&
        step.rawValue < Step.SealBox.rawValue
    } }

    var body: some View {
        let reader = GeometryReader { geometry in
            VStack {
                Spacer()
                VStack(alignment: .center) {
                    switch step {
                    case .Randomize: Randomize()
                    case .DropDice: DropDice()
                    case .FillEmptySlots: FillEmptySlots()
                    case .ScanFirstTime: ScanFirstTime(diceKey: self.$diceKeyScanned)
                    case .CreateBackup: BackupDiceKey(
                        onComplete: { self.step = Step(rawValue: step.rawValue + 1)! },
                        onBackedOut: { self.step = Step(rawValue: step.rawValue - 1)! },
                        thereAreMoreStepsAfterBackup: true,
                        diceKey: Binding<DiceKey>(
                                get: { diceKeyScanned ?? DiceKey.Example },
                                set: { newValue in diceKeyScanned = newValue }
                            ),
                        backupDiceKeyState: backupDiceKeyState
                        )
                    case .SealBox: SealBox()
                    case .Done: InstructionsDone(createdDiceKey: diceKeyScanned != nil, backedUpSuccessfully: backupSuccessful)
                    }
                }.padding(.horizontal, 15)
                Spacer()
                // Forward / Back nav
                if step != .CreateBackup {
                    StepFooterView(
                        goTo: {
                            if let newStep = Step(rawValue: $0) {
                                step = newStep
                            } else {
                                if let diceKey = self.diceKeyScanned, $0 > last {
                                    onSuccess?(diceKey)
                                }
                                self.presentationMode.wrappedValue.dismiss()
                            }
                        },
                        step: step.rawValue,
                        prev: step.rawValue > 0 ? step.rawValue - 1 : nil,
                        next: step.rawValue + 1,
                        setMaySkip: step == .ScanFirstTime && !userChoseToAllowSkipScanningStep ? { userChoseToAllowSkipScanningStep = true
                        } :
                            nil,
                        isLastStep: step == .Done
                    )
                }
                VStack {
                    Warning(message: "Do not close the box before the final Step.")
                        .padding(.vertical, 5)
                    HStack {}.frame(height: geometry.safeAreaInsets.bottom)
                }.foregroundColor(.white)
                .background(Color.warningBackground)
                .showIf(showWarning)
            }.edgesIgnoringSafeArea(.bottom)}
            .navigationTitle("Assembly Instructions")
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.primaryAction) {
                    Text("Step \(step.rawValue) of \(Step.SealBox.rawValue)").foregroundColor(Color.DiceKeysNavigationForeground).font(.body)
                }
            }
#if os(iOS)
        reader.navigationBarTitleDisplayMode(.inline).navigationBarDiceKeyStyle()
#endif
        return reader
    }
}

struct AssemblyInstructions_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        AppMainView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

//        CreateBackup(diceKey: DiceKey.createFromRandom())
//            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

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
        #else
        AssemblyInstructions(step: .Randomize)
        AssemblyInstructions(step: .DropDice)
        AssemblyInstructions(step: .FillEmptySlots)
        AssemblyInstructions(step: .ScanFirstTime)
        AssemblyInstructions(step: .CreateBackup)
        #endif
    }
}
