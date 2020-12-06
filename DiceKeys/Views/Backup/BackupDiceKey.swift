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

struct BackupToStickeys: View {
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

struct BackupDiceKey: View {
    let diceKey: DiceKey
    @State var mode: Mode?
    @State var step: Int = 0

    enum Mode {
        case Stickeys
        case DiceKey
        case Words
    }

    var body: some View {
        if mode == .Stickeys {
            BackupToStickeys(diceKey: diceKey, step: self.$step)
        } else {
//            GeometryReader { geometry in
            HStack {
                Spacer()
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                    Spacer()
                    NavigationLink(
                        destination: BackupToStickeys(diceKey: diceKey, step: self.$step),
                        label: {
                            VStack {
                                HStack {
                                    Spacer()
                                    DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue).scaleEffect(0.825)
                                    Spacer()
                                    StickerTargetSheet(diceKey: diceKey, showLettersBeforeIndex: 12, highlightAtIndex: 12).aspectRatio(contentMode: .fit)
                                }
                                Text("Create a Backup using Stickeys").font(.title2)
                                    .foregroundColor(Color.black)
                            }
                        }
                    )
//                    HStack {
//                        Text("Don't have Stickies?").font(.footnote)
//                        Link("Order a set", destination: URL(string: "https://dicekeys.com/store")!).font(.footnote)
//                    }.padding(.top, 5)
                    Spacer()
                    NavigationLink(
                        destination: BackupToStickeys(diceKey: diceKey, step: self.$step),
                        label: {
                            VStack {
                                HStack {
                                    Spacer()
                                    DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue).scaleEffect(0.825)
                                    Spacer()
                                    DiceKeyView(diceKey: diceKey, diceBoxColor: .alexandrasBlue, diePenColor: .alexandrasBlue).scaleEffect(0.825)
                                    Spacer()
                                }

                                //                                Image("Backup to DiceKey")
//                                    .renderingMode(.template)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .foregroundColor(Color.blue)
                                Text("Create a Backup DiceKey").font(.title2)                  .foregroundColor(Color.black)
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
            }
//            }
        }
    }
}

struct BackupDiceKey_Previews: PreviewProvider {
    static var previews: some View {

        BackupToStickeysIntro(diceKey: DiceKey.createFromRandom())
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        BackupDiceKey(diceKey: DiceKey.createFromRandom())
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))


        AssemblyInstructions()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        
        AppMainView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
