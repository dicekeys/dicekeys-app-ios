//
//  DiceKeyStorageOptions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct DiceKeyStorageOptions: View {
    let diceKey: DiceKey
    @StateObject var diceKeyState: UnlockedDiceKeyState

    var body: some View {
        GeometryReader { geometry in
        HStack {
            Spacer(minLength: 20)
            VStack {
                Spacer()

//                Toggle(isOn: $diceKeyState.isCenterFaceStored ) {
//                    HStack {
//                        Spacer()
//                        VStack {
//                            DieView(face: diceKey.centerFace,
//                                        dieSize: geometry.size.shorterSide / 3, faceBorderColor: Color.gray)
//                            Text("Store the Center Die").font(.title2).bold().padding(.top, 3).padding(.top, 3)
//                            Text("This app will display it on its home screen.").font(.footnote).padding(.top, 3)
//                        }
//                        Spacer()
//                    }
//                }
//                Spacer()
                Toggle(isOn: $diceKeyState.isDiceKeyStored ) {
                    HStack {
                        Spacer()
                        VStack {
                            ZStack {
                                Image("Phonelet").resizable().aspectRatio(contentMode: .fit).frame(width: geometry.size.shorterSide / 2.5)
                                DiceKeyView(diceKey: diceKey, diceBoxColor: Color.alexandrasBlue).frame(width: geometry.size.shorterSide / 3, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            }
                            Text("Store the DiceKey").font(.title2).bold().padding(.top, 3)
                        }
                        Spacer()
                    }
                }
                VStack(alignment: .leading) {
                    Text("The center die will appear in the home screen.").font(.body)
                    Text("The other 24 dice will be encrypted, and your TouchID, FaceID, or PIN will unlock them.").font(.body)
                    .padding(.top, 10)
                }.padding(.top, 3)
                Spacer()
            }
            Spacer(minLength: 20)
        }}
    }
}

struct DiceKeyStorageOptions_Previews: PreviewProvider {
    static let diceKey = DiceKey.createFromRandom()
    @StateObject static var diceKeyState = UnlockedDiceKeyState(diceKey)

    static var previews: some View {
        DiceKeyStorageOptions(diceKey: diceKey, diceKeyState: DiceKeyStorageOptions_Previews.diceKeyState)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
