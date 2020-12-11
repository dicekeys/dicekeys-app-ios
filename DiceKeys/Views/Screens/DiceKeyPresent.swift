//
//  DiceKeyPresent.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/27.
//

import SwiftUI

//struct ChooseValueToDerive: View {
//    let diceKey: DiceKey
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                DiceKeyView(diceKey: diceKey, showLidTab: true)
//
//                NavigationLink(
//                    destination: Text("Derive Value"),
//                    label: {
//                        Text("Derive value for")
//                    })
//            }
//        }
//    }
//}

//private func defaultDiceKeyName(diceKey: DiceKey) -> String {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    return "DiceKey with  \(diceKey.faces[12].letter.rawValue)\(diceKey.faces[12].digit.rawValue) in center (\(formatter.string(from: Date())))"
//}

struct NavBarAccessor: UIViewControllerRepresentable {
    var callback: (UINavigationBar) -> Void
    private let proxyController = ViewController()

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavBarAccessor>) ->
                              UIViewController {
        proxyController.callback = callback
        return proxyController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavBarAccessor>) {
    }

    typealias UIViewControllerType = UIViewController

    private class ViewController: UIViewController {
        var callback: (UINavigationBar) -> Void = { _ in }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let navBar = self.navigationController {
                self.callback(navBar.navigationBar)
            }
        }
    }
}

struct DiceKeyPresentNavigationFooter: View {
    @Binding var diceKey: DiceKey
    var diceKeyState: UnlockedDiceKeyState
    var geometry: GeometryProxy

    var size: CGSize { geometry.size }

    @State private var isBackupActive = false

    var BottomButtonCount: Int = 3
    var BottomButtonFractionalWidth: CGFloat {
        0.9 / CGFloat(BottomButtonCount)
    }

    var body: some View {
        VStack {
        ZStack {
            NavigationLink(destination: BackupDiceKey(diceKey: $diceKey, onComplete: { isBackupActive = false }), isActive: $isBackupActive, label: { EmptyView() })
                .position(x: 0, y: 0).frame(width: 0, height: 0).hidden()
            HStack(alignment: .top) {
                Spacer()
                NavigationLink(destination: SeedHardwareSecurityKey()) {
                    VStack {
                        Image("USB Key")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: min(size.width, size.height)/10, alignment: .center)
                        Text("Seed a Hardware Key").multilineTextAlignment(.center).font(.footnote)
                    }
                }.frame(width: size.width * BottomButtonFractionalWidth, alignment: .center)
                NavigationLink(destination: DiceKeyWithDerivedValue(diceKey: diceKey)) {
                    VStack {
                        VStack {
                        Image(systemName: "arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Image(systemName: "ellipsis.rectangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        }.frame(height: min(size.width, size.height)/10, alignment: .center)
                        Text("Derive a Secret or Password").multilineTextAlignment(.center).font(.footnote)
                    }
                }.frame(width: size.width * BottomButtonFractionalWidth, alignment: .center)
                Button(action: { isBackupActive = true }, label: {
                    VStack {
                        Image("Backup to DiceKey")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                maxWidth: size.width * BottomButtonFractionalWidth,
                                maxHeight: min(size.width, size.height)/10,
                                alignment: .center
                            )
                        Text("Backup this Key").multilineTextAlignment(.center).font(.footnote)
                    }
                }).frame(width: size.width * BottomButtonFractionalWidth, alignment: .center)
//                NavigationLink(destination: DiceKeyStorageOptions(diceKey: diceKey)) {
//                    VStack {
//                        ZStack {
//                            Image("Phonelet")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(height: min(size.width, size.height)/10, alignment: .center)
//                            if diceKeyState.isDiceKeyStored {
//                                Image("DiceKey Icon")
//                                    .renderingMode(.template)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .frame(height: min(size.width, size.height)/24, alignment: .center)
//                            }
//                        }
//                        if diceKeyState.isDiceKeyStored {
//                            Text("Key is Stored on this Device").multilineTextAlignment(.center).font(.footnote)
//                        } else {
//                            Text("Store Key on this Device").multilineTextAlignment(.center).font(.footnote)
//                        }
//                    }
//                }.frame(width: size.width * BottomButtonFractionalWidth, alignment: .center)
                Spacer()
            }
        }.padding(.bottom, geometry.safeAreaInsets.bottom)
        .padding(.top, 5)
        }.background(Color(UIColor.systemFill))
    }
}

struct DiceKeyPresent: View {
    @Binding var diceKey: DiceKey {
        mutating didSet {
            _diceKeyState = ObservedObject(initialValue: UnlockedDiceKeyState.forDiceKey(diceKey))
        }
    }

    let onForget: () -> Void

    @ObservedObject var diceKeyState: UnlockedDiceKeyState

    init(diceKey: Binding<DiceKey>, onForget: @escaping () -> Void) {
        self._diceKey = diceKey
        self.onForget = onForget
        self._diceKeyState = ObservedObject(initialValue: UnlockedDiceKeyState.forDiceKey(diceKey.wrappedValue))
    }

//    @State private var isDiceKeyWithDerivedValueActive = false
//    @State private var derivableName: String?
    @State private var navBarHeight: CGFloat = 0

    @State private var geometry: GeometryProxy?
    var size: CGSize {
        geometry?.size ?? CGSize(width: 0, height: 0)
    }

    var storageButton: some View {
        NavigationLink(destination: DiceKeyStorageOptions(diceKey: diceKey)) {
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .center, content: {
                    Image("Phonelet")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.DiceKeysNavigationForeground)
                        .aspectRatio(contentMode: .fit)
                    if diceKeyState.isDiceKeyStored {
                        Image("DiceKey Icon")
                            .renderingMode(.template)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.DiceKeysNavigationForeground)
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(2/3)
                    }
                }).aspectRatio(contentMode: .fit)
                Text(diceKeyState.isDiceKeyStored ? "Stored" : "Store")
            }.frame(maxHeight: navBarHeight)
        }
    }

    var body: some View {
        GeometryReader { geometry in
//        NavigationView {
            VStack {
//                NavigationLink(destination: DiceKeyWithDerivedValue(diceKey: diceKey, derivableName: $derivableName), isActive: $isDiceKeyWithDerivedValueActive, label: { EmptyView() })
//                    .position(x: 0, y: 0).frame(width: 0, height: 0).hidden()
                Spacer()
                DiceKeyView(diceKey: diceKey, showLidTab: true)
//                if let derivables = GlobalState.instance.derivables {
//                    if derivables.count > 0 {
//                        Menu {
//                            ForEach(derivables) { derivable in
//                                Button(derivable.name) {
//                                    derivableName = derivable.name
//                                    isDiceKeyWithDerivedValueActive = true
//                                }
//                            }
//                        } label: { VStack {
//                            Image(systemName: "arrow.down")
//                            Image(systemName: "ellipsis.rectangle.fill")
//                            Text("Derive Secret")
//                            }
//                        }
//                    }
//                }
                Spacer()
                DiceKeyPresentNavigationFooter(diceKey: $diceKey, diceKeyState: diceKeyState, geometry: geometry)
            }
//        }.navigationViewStyle(StackNavigationViewStyle())}
        }.navigationViewStyle(StackNavigationViewStyle())
        .navigationTitle(diceKeyState.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                Button(action: {
                    self.onForget()
                }) {
                    VStack {
                        Image(systemName: "lock")
                        Text(diceKeyState.isDiceKeyStored ? "Lock" : "Forget")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                storageButton
            }
        }.edgesIgnoringSafeArea(.bottom)
        .background(
            NavBarAccessor { navBar in self.navBarHeight = navBar.bounds.height }
        )
    }
}

struct TestDiceKeyPresent: View {
//    @State var diceKeyState: UnlockedDiceKeyState = UnlockedDiceKeyState(DiceKey.createFromRandom())
    @State var diceKey = DiceKey.createFromRandom()

    var body: some View {
//        NavigationView {
            DiceKeyPresent(
                diceKey: $diceKey,
                onForget: {}
            )
        }
//    }
}

struct DiceKeyPresent_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TestDiceKeyPresent()
        }.previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//
//        DerivedFromDiceKey(diceKey: diceKey) {
//            Text("Derive a Password, Key, or Secret")
//        }
    }
}
