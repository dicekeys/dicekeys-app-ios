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
    let diceKey: DiceKey
    @Binding var nickname: String

    @State var inNicknameEditingMode: Bool = false

    enum Destination {
        case Stickeys
    }
    @State private var destinationToNavigateTo: Destination?
    @State private var isNavigationActive = false

//    func navigate(to destination: Destination) {
//        destinationToNavigateTo = destination
//        isNavigationActive = true
//    }
//
//    struct RouteToDestination: View {
//        let destination: Destination?
//
//        var body: some View {
//            switch destination {
//            case .Stickeys:
//                BackupCard(diceKey: DiceKey.createFromRandom())
//            default:
//                EmptyView()
//            }
//        }
//    }
    var BottomButtonCount: Int = 3
    var BottomButtonFractionalWidth: CGFloat {
        CGFloat(1) / CGFloat(BottomButtonCount + 1)
    }

    var body: some View {
        GeometryReader { geometry in
        NavigationView {
            VStack {
//                NavigationLink(destination: RouteToDestination(destination: self.destinationToNavigateTo), isActive: $isNavigationActive) { EmptyView() }.hidden()
                Spacer()
                NicknameEditingField(nickname: $nickname).hideIf(!inNicknameEditingMode)
                Spacer()
                DiceKeyView(diceKey: diceKey, showLidTab: true)
                Menu {
                    Button("Password for A") { print("DQ") }
                    Button("Password for B") { print("Babies") }
                } label: { VStack {
                    Image(systemName: "arrow.down")
                    Image(systemName: "ellipsis.rectangle.fill")
                    Text("Derive Secret")
                } }
                Spacer()
                VStack {
                ZStack {
                    HStack {
                        Spacer()
                        NavigationLink(destination: SeedHardwareSecurityKey()) {
                            VStack {
                                Image(systemName: "key")
                                Text("Seed Key").font(.footnote)
                            }
                        }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                        NavigationLink(destination: BackupDiceKey(diceKey: diceKey)) {
                            VStack {
                                Image(systemName: "doc.on.doc")
                                Text("Backup").font(.footnote)
                            }
                        }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                        NavigationLink(destination: DiceKeyStorageOptions()) {
                            VStack {
                                ZStack {
                                    Image(systemName: "iphone")
                                    Image(systemName: "checkmark").foregroundColor(.green)
                                }
                                Text("Saved").font(.footnote)
                            }
                        }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                        Spacer()
                    }
                }.padding(.bottom, geometry.safeAreaInsets.bottom)
                .padding(.top, 5)
                }.background(Color(UIColor.systemFill))
            }.navigationTitle(nickname)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        }}
    }
}

let diceKey = DiceKey.createFromRandom()
struct TestDiceKeyPresent: View {
    @State var nickname = defaultDiceKeyName(diceKey: diceKey)

    var body: some View {
        DiceKeyPresent(
            diceKey: diceKey,
            nickname: $nickname
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
