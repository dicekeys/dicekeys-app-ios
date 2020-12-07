//
//  BackupDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct BackupToStickeysIntro: View {
    let diceKey: DiceKey

    var body: some View {
//        GeometryReader { geometry in
        VStack {
            Instruction("Unwrap your Stickeys Kit")
            Spacer()
            HStack {
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0) {
                    Text("5 Sticker Sheets").font(.title2)
                    StickerSheet()
                }
                Spacer()
                VStack(alignment: .center, spacing: 0) {
                    Text("1 Target Sheet").font(.title2)
                    StickerTargetSheet(diceKey: diceKey)
                }
            }
            Spacer()
            Instruction("Next, you will create a copy of your DiceKey on the target sheet by placing stickers.")
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                Text("Out of Stickeys? You can ")
                Link("order more", destination: URL(string: "https://dicekeys.com/store")!)
                Text(".")
            }.padding(.top, 30)
            Spacer()
        }
        }
//    }
}

struct BackupToStickeysSteps: View {
    let diceKey: DiceKey
    @Binding var step: Int

    var body: some View {
        if step == 0 {
            BackupToStickeysIntro(diceKey: diceKey)
        } else if step >= 1 && step <= 25 {
            Instruction("Construct your Backup")
            Spacer()
//            Button(action: { self.next() }, label: {
//            })
            TransferSticker(diceKey: diceKey, faceIndex: step - 1)
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
                // To ensure consistent spacing as we walk through instructions
                // render instructions for all 25 dice and hide the 24 not being
                // shown right now
                ForEach(0..<25) { index in
                    TransferStickerInstructions(diceKey: diceKey, faceIndex: index).if( index != step - 1 ) { $0.hidden() }
                }
            }.padding(.top, 20)
            Spacer()
        } else {
            EmptyView()
        }
    }
}

struct BackupToStickeys: View {
    @Binding var originalDiceKey: DiceKey
    @State var backupScanned: DiceKey?
    @State var step: Int = 0

    let last = 26

    var body: some View {
        VStack {
            if step < 26, let diceKey = originalDiceKey {
                BackupToStickeysSteps(diceKey: diceKey, step: self.$step)
            } else {
                ValidateBackup(originalDiceKey: self.$originalDiceKey, backupScanned: self.$backupScanned)
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
                        Text("Previous").font(.title3)
                    }
                }.showIf( step > 1 )
                Spacer()
                Button { step += 1 } label: {
                    HStack {
                        Text( step == last ? "Done" : "Next").font(.title3)
                        Image(systemName: "chevron.forward")
                    }
                }
                Spacer()
                Button { step = 26 } label: {
                    Image(systemName: "chevron.forward.2")
                }.showIf( step < 26 )
                Spacer()
            }
        }.padding(.horizontal, 10).padding(.bottom, 10)
    }
}

struct BackupDiceKey: View {
    @Binding var diceKey: DiceKey
    @State var mode: Mode?
//    @State var step: Int = 0

    enum Mode {
        case Stickeys
        case DiceKey
        case Words
    }

    var body: some View {
        if mode == .Stickeys {
            BackupToStickeys(originalDiceKey: self.$diceKey)
        } else {
//            GeometryReader { geometry in
            HStack {
                Spacer()
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                    Spacer()
                    NavigationLink(
                        destination: BackupToStickeys(originalDiceKey: self.$diceKey),
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
                                    StickerTargetSheet(diceKey: diceKey, showLettersBeforeIndex: 12, highlightAtIndex: 12, foregroundColor: Color.alexandrasBlue, orientation: .portrait)
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                    Spacer()
                                }
                                Text("Create a Backup using Stickeys").font(.title).foregroundColor(.alexandrasBlue)
                            }
                        }
                    )
//                    HStack {
//                        Text("Don't have Stickies?").font(.footnote)
//                        Link("Order a set", destination: URL(string: "https://dicekeys.com/store")!).font(.footnote)
//                    }.padding(.top, 5)
                    Spacer()
                    NavigationLink(
                        destination: BackupToStickeys(originalDiceKey: $diceKey),
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
                                    DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue)
                                    Spacer()
                                }
                                Text("Create a Backup DiceKey").font(.title).foregroundColor(.alexandrasBlue)
                            }
                        }
                    )
//                    HStack {
//                        Text("Need another DiceKey?").font(.footnote)
//                        Link("Order one", destination: URL(string: "https://dicekeys.com/store")!).font(.footnote)
//                    }.padding(.top, 5)
                    /*
                    Spacer()
                    Button(action: { mode = .Stickeys }) {
                        Text("Write 30 Words")
                    }
                     */
                    Spacer()
                }
                Spacer()
            }.padding(.horizontal, 10)
//            }
        }
    }
}

private struct TestBackupDiceKey: View {
    @State var diceKey: DiceKey = DiceKey.createFromRandom()

    var body: some View {
        BackupDiceKey(diceKey: $diceKey)
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
