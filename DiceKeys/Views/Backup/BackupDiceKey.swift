//
//  BackupDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI
import Combine

enum BackupTarget: String {
    case DiceKey
    case Stickeys
}

struct ChooseBackupTarget: View {
    var diceKey: DiceKey
    let choice: (BackupTarget) -> Void

    var body: some View {
        VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            Instruction("Make a backup of your DiceKey by copying it.")
            Spacer()
            Button(action: { choice(.Stickeys) },
                label: {
                    VStack {
                        HStack(alignment: .center, spacing: 0) {
                            Spacer()
                            DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue,
                                aspectRatioMatchStickeys: true
                            ).frame(minWidth: 0, maxWidth: .infinity)
                            Image(systemName: "arrow.right.circle.fill")
                                .renderingMode(.template)
                                .foregroundColor(Color.alexandrasBlue)
                                .scaleEffect(2.0)
                                .padding(.horizontal, 20)
                            StickerTargetSheet(diceKey: diceKey, showLettersBeforeIndex: 12, atDieIndex: 12, foregroundColor: Color.alexandrasBlue, orientation: .portrait)
                                .frame(minWidth: 0, maxWidth: .infinity)
                            Spacer()
                        }
                        Text("Use a Stickeys Kit").font(.title).foregroundColor(.alexandrasBlue)
                    }
                }
            ).frame(minHeight: 0, maxHeight: .infinity)
            .buttonStyle(PlainButtonStyle())
            Spacer(minLength: 20)
            Button(action: { choice(.DiceKey) },
                label: {
                    VStack {
                        HStack(alignment: .center, spacing: 0) {
                            Spacer()
                            DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue,
                                aspectRatioMatchStickeys: true
                            ).frame(minWidth: 0, maxWidth: .infinity)
                            Image(systemName: "arrow.right.circle.fill")
                                .renderingMode(.template)
                                .foregroundColor(Color.alexandrasBlue)
                                .scaleEffect(2.0)
                                .padding(.horizontal, 20)
                            DiceKeyCopyInProgress(diceKey: diceKey, atDieIndex: 12, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue
                            ).frame(minWidth: 0, maxWidth: .infinity)
                            Spacer()
                        }
                        Text("Use a DiceKey Kit").font(.title).foregroundColor(.alexandrasBlue)
                    }
                }
            ).frame(minHeight: 0, maxHeight: .infinity)
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
}

private struct BackupSteps: View {
    let diceKey: DiceKey
    let target: BackupTarget

    // Step 0: choose backup target
    // Step 1: Introduction
    // Step 2-26, assign key
    // Step 27, validate
    let step: Int

    var faceIndex: Int { step - 2 }

    var body: some View {
        if step == 1 {
            switch target {
            case .Stickeys: BackupToStickeysIntroduction(diceKey: diceKey)
            case .DiceKey: BackupToDiceKeysKitIntroduction(diceKey: diceKey)
            }
        } else if step >= 2 && step <= 26 {
            Instruction("Construct your Backup")
            Spacer()
            switch target {
            case .Stickeys: TransferSticker(diceKey: diceKey, faceIndex: faceIndex)
            case .DiceKey: TransferDie(diceKey: diceKey, faceIndex: faceIndex)
            }

            ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                // To ensure consistent spacing as we walk through instructions
                // render instructions for all 25 dice and hide the 24 not being
                // shown right now
                ForEach(0..<25) { index in
                    switch target {
                    case .Stickeys: TransferStickerInstructions(diceKey: diceKey, faceIndex: index).if( index != faceIndex ) { $0.hidden() }
                    case .DiceKey: TransferDieInstructions(diceKey: diceKey, faceIndex: index).if( index != faceIndex) { $0.hidden() }
                    }
                }
            }.padding(.top, 20)
            Spacer()
        } else {
            EmptyView()
        }
    }
}

class BackupDiceKeyState: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private var notificationSubscription: AnyCancellable?

    init(target: BackupTarget? = nil) {
        self.target = target
        notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
            self.objectWillChange.send()
        }
    }

    @Published var step: Int = 0 {
        willSet { objectWillChange.send() }
    }
    @Published var target: BackupTarget? {
        willSet { objectWillChange.send() }
    }
}

struct BackupDiceKey: View {
    let onComplete: () -> Void
    var onBackedOut: (() -> Void)?
    var thereAreMoreStepsAfterBackup: Bool = false
    @Binding var diceKey: DiceKey
    @StateObject var backupDiceKeyState = BackupDiceKeyState()

    @State var backupScanned: DiceKey?
    @State var maySkipValidationStep = false

    var step: Int { backupDiceKeyState.step }
    var target: BackupTarget? { backupDiceKeyState.target }

    var validationRequired: Bool {
        step == validationStep && !DiceKey.rotationIndependentEquals(diceKey, backupScanned) && !maySkipValidationStep
    }

    private let validationStep = 27
    private let lastStep = 27

    var body: some View {
        VStack {
            if let target = self.target, step > 0 {
                if step < validationStep, let diceKey = diceKey {
                    BackupSteps(diceKey: diceKey, target: target, step: step)
                } else {
                    ValidateBackup(target: target, originalDiceKey: self.$diceKey, backupScanned: self.$backupScanned)
                }
            } else {
                ChooseBackupTarget(diceKey: diceKey, choice: {
                    backupDiceKeyState.target = $0
                    backupDiceKeyState.step = 1
                })
            }
            StepFooterView(
                goTo: {
                    if $0 < 0 {
                        onBackedOut?()
                    } else if $0 <= lastStep {
                        backupDiceKeyState.step = $0
                    } else {
                        onComplete()
                    }
                },
                step: step,
                prevPrev: 1,
                prev: (step > 0 || onBackedOut != nil) ? step - 1 : nil,
                next: step == 0 ? nil : step + 1,
                nextNext: validationStep,
                setMaySkip: validationRequired ? { maySkipValidationStep = true } :
                    step == 0 && thereAreMoreStepsAfterBackup ? { onComplete() } :
                    nil,
                isLastStep: step == lastStep && !thereAreMoreStepsAfterBackup
            )
        }.padding(.horizontal, 10).padding(.bottom, 10)
    }
}

private struct TestBackupDiceKey: View {
    @State var diceKey: DiceKey = DiceKey.createFromRandom()
    @StateObject var backupDiceKeyState = BackupDiceKeyState()

    var body: some View {
        BackupDiceKey(onComplete: {}, diceKey: $diceKey, backupDiceKeyState: backupDiceKeyState)
    }
}

struct BackupDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        TestBackupDiceKey()
            .previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))

        TestBackupDiceKey()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        TestBackupDiceKey()
            .previewLayout(.fixed(width: 1024, height: 768))
//        BackupToStickeysIntro(diceKey: DiceKey.createFromRandom())
//                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//
//
//
//        AssemblyInstructions()
//            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//
//        AppMainView()
//            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
