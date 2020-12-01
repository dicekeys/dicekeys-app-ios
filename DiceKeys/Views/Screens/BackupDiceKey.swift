//
//  BackupDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct BackupToStickeysPreview {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
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
            Text("Stickeys!")
        } else {
//            GeometryReader { geometry in
            HStack {
                Spacer()
                VStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
                    Spacer()
                    Button(action: { mode = .Stickeys }) {
                        VStack {
                            HStack {
                                Image("DiceKey Icon").resizable().aspectRatio(contentMode: .fit)
                                Image(systemName: "arrow.right").resizable().aspectRatio(contentMode: .fit).scaleEffect(0.5)
                                Image("Assembling Stickeys").resizable().aspectRatio(contentMode: .fit)
                            }
//                            Image("Backup To Stickeys").resizable().aspectRatio(contentMode: .fit)
                            Text("Create a Backup from Stickeys").font(.title2)
                        }
                    }
                    HStack {
                        Text("Don't have Stickies?").font(.footnote)
                        Link("Order a set", destination: URL(string: "https://dicekeys.com/store")!).font(.footnote)
                    }.padding(.top, 5)
                    Spacer()
                    Button(action: { mode = .Stickeys }) {
                        VStack {
                            Image("Backup to DiceKey").resizable().aspectRatio(contentMode: .fit)
                            Text("Create a Backup DiceKey").font(.title2)
                        }
                    }
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
