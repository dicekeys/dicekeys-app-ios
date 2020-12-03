//
//  DiceKeyPresent.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/27.
//

import SwiftUI

struct ChooseValueToDerive: View {
    let diceKey: DiceKey

    var body: some View {
        NavigationView {
            VStack {
                DiceKeyView(diceKey: diceKey, showLidTab: true)

                NavigationLink(
                    destination: Text("Derive Value"),
                    label: {
                        Text("Derive value for")
                    })
            }
        }
    }
}

private func defaultDiceKeyName(diceKey: DiceKey) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return "DiceKey with  \(diceKey.faces[12].letter.rawValue)\(diceKey.faces[12].digit.rawValue) in center (\(formatter.string(from: Date())))"
}

struct NicknameEditingField: View {
    @Binding var nickname: String

    let nicknameFieldFont =  UIFont.preferredFont(forTextStyle: .title2)
    let nicknameFieldIdealSize = NSString("A reasonably long nickname").size(withAttributes: [ NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title2)]).width
    let nicknameFieldMaxSize = NSString("A truly unreasonably gigantic nickname").size(withAttributes: [ NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title2)]).width

    var body: some View {
        HStack {
            Spacer()
            TextField(
                "Nickname",
                 text: $nickname
            ) // { isEditing in
//                        // self.isEditing = isEditing
//                    } onCommit: {
//                        // validate(name: username)
//                    }
            .font(Font(nicknameFieldFont))
            .multilineTextAlignment(.center)
            .border(Color(UIColor.separator))
            .frame(
                maxWidth: min(nicknameFieldMaxSize, UIScreen.main.bounds.size.width * 0.9)
            )
            Spacer()
        }
    }
}

struct DiceKeyPresent: View {
    @ObservedObject var diceKeyState: DiceKeyState
    let onForget: () -> Void

    @State var inNicknameEditingMode: Bool = false

    @State private var isDiceKeyWithDerivedValueActive = false
    @State private var derivableName: String?
 
    var BottomButtonCount: Int = 3
    var BottomButtonFractionalWidth: CGFloat {
        CGFloat(1) / CGFloat(BottomButtonCount + 1)
    }
    
    var diceKey: DiceKey {
        diceKeyState.diceKey!
    }

    var body: some View {
        GeometryReader { geometry in
        NavigationView {
            VStack {
                NavigationLink(destination: DiceKeyWithDerivedValue(derivableName: $derivableName, diceKeyState: diceKeyState), isActive: $isDiceKeyWithDerivedValueActive, label: { EmptyView() }).hidden()
                Spacer()
                NicknameEditingField(nickname: $diceKeyState.nickname).hideIf(!inNicknameEditingMode)
                Spacer()
                DiceKeyView(diceKey: diceKey, showLidTab: true)
                if let derivables = GlobalState.instance.derivables {
                    if derivables.count > 0 {
                        Menu {
                            ForEach(derivables) { derivable in
                                Button(derivable.name) {
                                    derivableName = derivable.name
                                    isDiceKeyWithDerivedValueActive = true
                                }
                            }
                        } label: { VStack {
                            Image(systemName: "arrow.down")
                            Image(systemName: "ellipsis.rectangle.fill")
                            Text("Derive Secret")
                            }
                        }
                    }
                }
                Spacer()
                VStack {
                ZStack {
                    HStack {
                        Spacer()
                        NavigationLink(destination: SeedHardwareSecurityKey()) {
                            VStack {
                                Image("USB Key")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(geometry.size.width, geometry.size.height)/10, alignment: .center)
                                Text("Seed Key").font(.footnote)
                            }
                        }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                        NavigationLink(destination: BackupDiceKey(diceKey: diceKey)) {
                            VStack {
                                Image("Backup to DiceKey")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: min(geometry.size.width, geometry.size.height)/10, alignment: .center)
                                Text("Backup").font(.footnote)
                            }
                        }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                        NavigationLink(destination: DiceKeyStorageOptions(diceKey: diceKey, diceKeyState: diceKeyState)) {
                            VStack {
                                ZStack {
                                    Image(systemName: "iphone")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: min(geometry.size.width, geometry.size.height)/10, alignment: .center)
                                    Image("DiceKey Icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: min(geometry.size.width, geometry.size.height)/24, alignment: .center)
                                }
                                Text("Saved").font(.footnote)
                            }
                        }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                        Spacer()
                    }
                }.padding(.bottom, geometry.safeAreaInsets.bottom)
                .padding(.top, 5)
                }.background(Color(UIColor.systemFill))
            }
            .navigationTitle(diceKeyState.nickname)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                    Button(action: { self.onForget() }) {
                        Text(diceKeyState.isDiceKeyStored ? "Close" : "Forget")
                    }
                }
                ToolbarItem(placement: ToolbarItemPlacement.primaryAction) {
                    if inNicknameEditingMode {
                        Button(action: { inNicknameEditingMode = false }, label: {
                            Image(systemName: "checkmark")
                        })
                    } else {
                        Button(action: { inNicknameEditingMode = true }, label: {
                            Image(systemName: "pencil")
                        })
                    }
                }
            }.edgesIgnoringSafeArea(.bottom)
        }.navigationViewStyle(StackNavigationViewStyle())}
    }
}

struct TestDiceKeyPresent: View {
    @State var diceKeyState: DiceKeyState = DiceKeyState(DiceKey.createFromRandom())

    var body: some View {
        DiceKeyPresent(
            diceKeyState: diceKeyState,
            onForget: {}
       )
    }
}

struct DiceKeyPresent_Previews: PreviewProvider {
    static var previews: some View {
        TestDiceKeyPresent()
        .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//
//        DerivedFromDiceKey(diceKey: diceKey) {
//            Text("Derive a Password, Key, or Secret")
//        }
    }
}
