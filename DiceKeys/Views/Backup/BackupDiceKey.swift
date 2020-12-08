//
//  BackupDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

enum BackupTarget: String {
    case DiceKey
    case Stickeys
}

struct BackupSteps: View {
    let diceKey: DiceKey
    let target: BackupTarget
    @Binding var step: Int

    var faceIndex: Int { step - 1 }

    var body: some View {
        if step == 0 {
            switch target {
            case .Stickeys: BackupToStickeysIntroduction(diceKey: diceKey)
            case .DiceKey: BackupToDiceKeysKitIntroduction(diceKey: diceKey)
            }
        } else if step >= 1 && step <= 25 {
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

struct BackupToTarget: View {
    let target: BackupTarget
    let onComplete: () -> Void
    @Binding var originalDiceKey: DiceKey
    @Binding var step: Int
    @State var backupScanned: DiceKey?
    @State var maySkipValidationStep = false

    var validationRequired: Bool {
        step == validationStep && !DiceKey.rotationIndependentEquals(originalDiceKey, backupScanned) && !maySkipValidationStep
    }

    private let validationStep = 26
    private let lastStep = 26

    var body: some View {
        VStack {
            if step < 26, let diceKey = originalDiceKey {
                BackupSteps(diceKey: diceKey, target: target, step: self.$step)
            } else {
                ValidateBackup(target: target, originalDiceKey: self.$originalDiceKey, backupScanned: self.$backupScanned)
            }
            HStack {
                Spacer()
                Button(
                    action: { maySkipValidationStep = true },
                    label: { Text("Let me skip this step").font(.footnote) }
                ).padding(.bottom, 7).showIf( validationRequired )
                Spacer()
            }
            HStack {
                Spacer()
                Button { step = 0 } label: {
                    Image(systemName: "chevron.backward.2")
                }.showIf( step > 1)
                Spacer()
                Button { step -= 1 } label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Previous").font(.title2)
                    }
                }.showIf( step > 1 )
                Spacer()
                Button {
                    if step < lastStep {
                        step += 1
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack {
                        Text( step == lastStep ? "Done" : "Next").font(.title2)
                        Image(systemName: "chevron.forward")
                    }
                }.disabled( validationRequired )
                Spacer()
                Button { step = validationStep } label: {
                    Image(systemName: "chevron.forward.2")
                }.showIf( step < 26 )
                Spacer()
            }
        }.padding(.horizontal, 10).padding(.bottom, 10)
    }
}

struct BackupDiceKey: View {
    @Binding var diceKey: DiceKey
    let onComplete: () -> Void
    @State var mode: BackupTarget?
    @State var step: Int = 0

    var body: some View {
        if let target = mode {
            BackupToTarget(target: target, onComplete: onComplete, originalDiceKey: self.$diceKey, step: $step)
        } else {
            VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                Spacer()
                Button(action: { mode = .Stickeys },
                    label: {
                        VStack {
                            HStack(alignment: .center, spacing: 0) {
                                Spacer()
                                DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue)
                                    .frame(minWidth: 0, maxWidth: .infinity)
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
                )
                Spacer()
                Button(action: { mode = .DiceKey },
                    label: {
                        VStack {
                            HStack {
                                Spacer()
                                DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue)
                                Image(systemName: "arrow.right.circle.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(Color.alexandrasBlue)
                                    .scaleEffect(2.0)
                                    .padding(.horizontal, 20)
                                DiceKeyCopyInProgress(diceKey: diceKey, atDieIndex: 12, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue)
                                Spacer()
                            }
                            Text("Use a DiceKey Kit").font(.title).foregroundColor(.alexandrasBlue)
                        }
                    }
                )
                Spacer()
            }.navigationBarTitle("Create a backup").padding(.horizontal, 10)
        }
    }
}

private struct TestBackupDiceKey: View {
    @State var diceKey: DiceKey = DiceKey.createFromRandom()

    var body: some View {
        BackupDiceKey(diceKey: $diceKey, onComplete: {})
    }
}

struct BackupDiceKey_Previews: PreviewProvider {
    static var previews: some View {
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
