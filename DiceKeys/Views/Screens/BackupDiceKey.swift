//
//  BackupDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct BackupToStickeys: View {
    let diceKey: DiceKey
    @State var step: Int = 0
    var onSuccess: (() -> Void)?

    var body: some View {
        VStack {
            Spacer()
            TransferSticker(diceKey: diceKey, faceIndex: step)
            Spacer()
            HStack {
                Spacer()
                Button("Previous") { step = step - 1 }.disabled( step == 0)
                Spacer()
                if step < 24 {
                    Button("Next") { step = step + 1 }
                }
                Spacer()
            }.padding(.bottom, 10)
        }
    }
}

struct BackupDiceKey: View {
    let diceKey: DiceKey
    @State var mode: Mode?

    enum Mode {
        case Stickeys
        case DiceKey
        case Words
    }

    var body: some View {
        if mode == .Stickeys {
            BackupToStickeys(diceKey: diceKey) {
                // on success
            }
        } else {
//            GeometryReader { geometry in
            HStack {
                Spacer()
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                    Spacer()
                    NavigationLink(
                        destination: BackupToStickeys(diceKey: diceKey),
                        label: {
                            VStack {
//                                HStack {
//                                    Image("DiceKey Icon").resizable().aspectRatio(contentMode: .fit)
//                                    Image(systemName: "arrow.right").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.5)
//                                    Image("Assembling Stickeys").resizable().aspectRatio(contentMode: .fit)
//                                }
                                Image("Backup to Stickeys")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(Color.blue)
                                Text("Create a Backup from Stickeys").font(.title2)
                                    .foregroundColor(Color.black)
                            }
                        }
                    )
                    HStack {
                        Text("Don't have Stickies?").font(.footnote)
                        Link("Order a set", destination: URL(string: "https://dicekeys.com/store")!).font(.footnote)
                    }.padding(.top, 5)
                    Spacer()
                    NavigationLink(
                        destination: BackupToStickeys(diceKey: diceKey),
                        label: {
                            VStack {
                                Image("Backup to DiceKey")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(Color.blue)
                                Text("Create a Backup DiceKey").font(.title2)                  .foregroundColor(Color.black)
                            }
                        }
                    )
                    HStack {
                        Text("Need another DiceKey?").font(.footnote)
                        Link("Order one", destination: URL(string: "https://dicekeys.com/store")!).font(.footnote)
                    }.padding(.top, 5)
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
        BackupDiceKey(diceKey: DiceKey.createFromRandom())
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
