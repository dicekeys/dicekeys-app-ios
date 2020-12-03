//
//  DiceKeyStorageOptions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct DiceKeyStorageOptions: View {
    let diceKey: DiceKey
    @StateObject var diceKeyState: DiceKeyState

    var body: some View {
        GeometryReader { geometry in
        HStack {
            Spacer()
                VStack {
                    Spacer()
                    Button(action: { diceKeyState.setStoreNicknameOnly() }) {
                        VStack {
                            ZStack {
                                Image(systemName: "iphone")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(geometry.size.width, geometry.size.height)/3, alignment: .center)
                                Text(diceKeyState.nickname)
                                    .font(.footnote)
                                    .frame(width: min(geometry.size.width, geometry.size.height)/7.5)
                                    .lineLimit(4)
                                    .scaledToFill()
                            }
                            Text("Store only this DiceKey's nickname").font(.title2)
                        }
                    }.disabled( diceKeyState.whatToStore == .nicknameOnly )
                    Text("You will need to re-scan your DiceKey each time you need it.").font(.footnote)
                    Spacer()
        //            Button(action: { diceKeyState.setStorePublicKeys() }) {
        //                Text("Store public keys")
        //            }.disabled( diceKeyState.whatToStore == .publicKeys )
        //            Spacer()
                    Button(action: { diceKeyState.setStoreRawDiceKey(diceKey: diceKey) }) {
                        VStack {
                            ZStack {
                                Image(systemName: "iphone")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(geometry.size.width, geometry.size.height)/3, alignment: .center)
                                Image("DiceKey Icon")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)                            .frame(height: min(geometry.size.width, geometry.size.height)/7, alignment: .center)
                            }
                            Text("Store the DiceKey on this device").font(.title2)
                        }
                    }.disabled( diceKeyState.whatToStore == .rawDiceKey )
                    Text("You will need to use your TouchID, FaceID, or PIn to unlock it.").font(.footnote)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct DiceKeyStorageOptions_Previews: PreviewProvider {
    static let diceKey = DiceKey.createFromRandom()
    @StateObject static var diceKeyState = DiceKeyState(diceKey)

    static var previews: some View {
        DiceKeyStorageOptions(diceKey: diceKey, diceKeyState: DiceKeyStorageOptions_Previews.diceKeyState)
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
