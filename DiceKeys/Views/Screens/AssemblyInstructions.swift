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

private let warningBackgroundColor: Color = Color(hex: "E0585B")

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

private struct ValidateBackup: View {
    @Binding var originalDiceKey: DiceKey?
    @State var scanningOriginal: Bool = false
    @State var scanningCopy: Bool = false
    @State var backupDiceKey: DiceKey?

    var backupDiceKeyRotatedToMatchOriginal: DiceKey? {
        guard let original = originalDiceKey, let backup = backupDiceKey else { return nil }
        return original.mostSimilarRotationOf(backup)
    }

    var invalidIndexes: Set<Int> {
        guard let original = originalDiceKey else { return Set<Int>() }
        guard let backup = backupDiceKeyRotatedToMatchOriginal else { return Set<Int>() }
        return Set<Int>(
            (0..<25).filter { original.faces[$0].numberOfFieldsDifferent(fromOtherFace: backup.faces[$0]) > 0 }
        )
    }

    var perfectMatch: Bool {
        invalidIndexes.count == 0 && backupDiceKey != nil
    }

    var totalMismatch: Bool {
        invalidIndexes.count > 5
    }

    var body: some View {
        Instruction("Scan your backup to validate it.")
        Spacer()
        if scanningCopy || scanningOriginal {
            ScanDiceKey { diceKeyScanned in
                if self.scanningOriginal {
                    self.originalDiceKey = diceKeyScanned
                    self.scanningOriginal = false
                } else if self.scanningCopy {
                    self.backupDiceKey = diceKeyScanned
                    self.scanningCopy = false
                }
            }
            Spacer()
            RoundedTextButton("Cancel") { self.scanningCopy = false }
        } else if let backup = self.backupDiceKeyRotatedToMatchOriginal, let original = self.originalDiceKey {
            HStack(alignment: .top) {
                VStack {
                    DiceKeyView(diceKey: original)
                    RoundedTextButton("Re-scan") { self.scanningOriginal = true }
                }
                Spacer()
                VStack {
                    if totalMismatch {
                        DiceKeyView(diceKey: self.backupDiceKey!)
                    } else {
                        DiceKeyView(diceKey: backup, highlightIndexes: invalidIndexes)
                    }
                    RoundedTextButton("Re-scan copy") { self.scanningCopy = true }
                }
            }
            Spacer()
            if perfectMatch {
                Text("You made a perfect copy!").font(.largeTitle).foregroundColor(.green)
            } else if totalMismatch {
                Text("That key doesn't look at all like the key you scanned before.").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).foregroundColor(.red)
            } else {
                Text("You incorrectly copied the highlighted dice. You can fix the copy to match the original, or change the original to match the copy.").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).foregroundColor(.red)
            }
            Spacer()
        } else {
            HStack(alignment: .top) {
                VStack {
                    if let original = originalDiceKey {
                        DiceKeyView(diceKey: original)
                    } else {
                        Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).offset(x: 0, y: -50)
                    }
                    RoundedTextButton("Scan original") { self.scanningOriginal = true }
                }
                VStack {
                    Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).offset(x: 0, y: -50)
                    RoundedTextButton("Scan copy") { self.scanningCopy = true }
                }
            }
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
    }

    @State private var diceKeyScanned: DiceKey?
    @State private var diceKeyValidationResult: DiceKey?
    @State var step: Step = Step(rawValue: 1)!
    @State var substep: Int = 0

    private let first = Step.Randomize.rawValue
    private let last = Step.SealBox.rawValue

    let numberOfBackupSubsteps = 26

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
        ( step == .ScanFirstTime && diceKeyScanned == nil )
//            ||
//        ( step == .ValidateBackup && diceKeyValidationResult == nil ) // FIXE != diceKeyScanned )
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
            step = Step(rawValue: step.rawValue + 1) ?? Step.SealBox
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
                    case .CreateBackup: BackupToStickeys(diceKey: self.diceKeyScanned ?? DiceKey.Example, step: $substep)
    //                case .CreateBackup: BackupDiceKey(diceKey: self.diceKeyScanned ?? DiceKey.Example)
                    case .ValidateBackup: ValidateBackup(originalDiceKey: self.$diceKeyScanned)
                    case .SealBox: SealBox()
                    }
                }.padding(.horizontal, 15)
                Spacer()
                // Forward / Back nav
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
                            Text(step.rawValue == last ? "Done" : showSkipButton ? "Skip": "Next").font(.title3)
                            Image(systemName: "chevron.forward")
                       }
                    }
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
                .background(warningBackgroundColor)
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
