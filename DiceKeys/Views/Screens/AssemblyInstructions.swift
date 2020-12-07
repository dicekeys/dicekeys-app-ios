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

    var body: some View {
        Text(text)
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
        Instruction(createdDiceKey ? "You did it!" : "That's it!")
        Spacer()
        if !createdDiceKey {
            Instruction("There's nothing more to it. Go back to try it for real and scan in your DiceKey.")
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
        case ValidateBackup
        case SealBox
        case Done
    }

    @State private var diceKeyScanned: DiceKey?
    @State private var backupScanned: DiceKey?
    @State var step: Step = Step(rawValue: 1)!
    @State var substep: Int = 0
    @State var backupTarget: BackupTarget = .Stickeys

    @State var userChoseToAllowSkipScanningStep: Bool = false
    @State var userChoseToAllowSkipBackupStep: Bool = false

//    let diceKeyScannedNonNil = Binding<DiceKey>(
//        get: {diceKeyScanned ?? DiceKey.Example},
//        set: {newValue in diceKeyScanned = newValue}
//    )

    var maySkipBackupStep: Bool {
        userChoseToAllowSkipScanningStep || userChoseToAllowSkipBackupStep
    }

    var showSkipOption: Bool {
        (step == .ScanFirstTime && !userChoseToAllowSkipScanningStep) ||
        (step == .ValidateBackup && !maySkipBackupStep)
    }

    func onUserChoseToSkipThisStep() {
        if step == .ScanFirstTime {
            userChoseToAllowSkipScanningStep = true
        } else if step == .ValidateBackup {
            userChoseToAllowSkipBackupStep = true
        }
    }

    private let first = Step.Randomize.rawValue
    private let last = Step.Done.rawValue

    let numberOfBackupSubsteps = 26

    var backupSuccessful: Bool {
        DiceKey.rotationIndependentEquals(diceKeyScanned, backupScanned)
    }

    private var isPrevStepSubstep: Bool {
        step == .CreateBackup && substep > 0
    }

    private var isNextStepSubstep: Bool {
        step == .CreateBackup && substep < numberOfBackupSubsteps - 1
    }

    private var showWarning: Bool { get {
        step.rawValue > Step.Randomize.rawValue &&
        step.rawValue < Step.SealBox.rawValue
    } }

    private var showSkipButton: Bool { get {
        ( step == .ScanFirstTime && diceKeyScanned == nil && !userChoseToAllowSkipScanningStep ) ||
            ( step == .ValidateBackup && !maySkipBackupStep && !backupSuccessful ) // FIXE != diceKeyScanned )
    }}

    func fullStepBack() {
        step = Step(rawValue: step.rawValue - 1) ?? Step.Randomize
        if step == .CreateBackup && diceKeyScanned == nil {
            step = Step(rawValue: step.rawValue - 1)!
        }
    }

    func prev() {
        if isPrevStepSubstep {
            substep -= 1
        } else {
            fullStepBack()
        }
    }

    func fullStepForward() {
        if step.rawValue == last {
            // exit navigation layer
            if let diceKey = self.diceKeyScanned {
                onSuccess?(diceKey)
            }
            self.presentationMode.wrappedValue.dismiss()
        } else {
            step = Step(rawValue: step.rawValue + 1) ?? Step.Done
            if step == .CreateBackup && diceKeyScanned == nil {
                step = Step(rawValue: step.rawValue + 1)!
            }
        }
    }

    func next() {
        if isNextStepSubstep {
            substep += 1
        } else {
            fullStepForward()
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                VStack(alignment: .center) {
                    switch step {
                    case .Randomize: Randomize()
                    case .DropDice: DropDice()
                    case .FillEmptySlots: FillEmptySlots()
                    case .ScanFirstTime: ScanFirstTime(diceKey: self.$diceKeyScanned)
                    case .CreateBackup: BackupSteps(diceKey: self.diceKeyScanned ?? DiceKey.Example, target: .Stickeys, step: $substep)
                    case .ValidateBackup: ValidateBackup(target: backupTarget, originalDiceKey: Binding<DiceKey>(
                        get: { diceKeyScanned ?? DiceKey.Example },
                        set: { newValue in diceKeyScanned = newValue }
                    ), backupScanned: self.$backupScanned)
                    case .SealBox: SealBox()
                    case .Done: InstructionsDone(createdDiceKey: diceKeyScanned != nil, backedUpSuccessfully: backupSuccessful)
                    }
                }.padding(.horizontal, 15)
                Spacer()
                // Forward / Back nav
                HStack {
                    Spacer()
                    Button(
                        action: { onUserChoseToSkipThisStep() },
                        label: { Text("Let me skip this step").font(.footnote) }
                    ).padding(.bottom, 7).showIf(showSkipButton)
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button { fullStepBack() } label: {
                        Image(systemName: "chevron.backward.2")
                    }.showIf( isPrevStepSubstep)
                    Spacer()
                    Button { prev() } label: {
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Previous").font(.title3)
                        }
                    }.showIf(step.rawValue != first)
                    Spacer()
                    Button { next() } label: {
                        HStack {
                            Text(step.rawValue == last ? "Done" : "Next").font(.title3)
                            Image(systemName: "chevron.forward")
                        }
                    }.disabled(showSkipButton)
                    Spacer()
                    Button { fullStepForward() } label: {
                        Image(systemName: "chevron.forward.2")
                    }.showIf( isNextStepSubstep )
                    Spacer()
                }.padding(.bottom, 10)
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
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AssemblyInstructions_Previews: PreviewProvider {
    static var previews: some View {
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
    }
}
