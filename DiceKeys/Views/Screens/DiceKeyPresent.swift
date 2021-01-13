//
//  DiceKeyPresent.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/27.
//

import SwiftUI

#if os(iOS)
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
#endif

enum DiceKeyPresentPageContent: Equatable {
    case Backup
    case SeedHardwareKey
    case Derive(DerivationRecipeBuilderType)
    case Save
    case Default
}

struct DiceKeyPresentNavigationFooter: View {
    let pageContent: DiceKeyPresentPageContent
    let navigateTo: (DiceKeyPresentPageContent) -> Void
    let geometry: GeometryProxy

    @State private var isBackupActive = false

    var BottomButtonCount: Int = 3
    var BottomButtonFractionalWidth: CGFloat {
        0.9 / CGFloat(BottomButtonCount)
    }

    var body: some View {
        let view = VStack {
        ZStack {
            HStack(alignment: .top) {
                Spacer()
                Button(action: { navigateTo(.SeedHardwareKey) }) {
                    VStack {
                        Image("USB Key")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: min(geometry.size.width, geometry.size.height)/10, alignment: .center)
                        Text("Seed a SoloKey").multilineTextAlignment(.center).font(.footnote)
                    }
                }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                .if( pageContent == .SeedHardwareKey ) { $0.colorInvert() }
                DerivationRecipeMenu({ newPageContent in
                    navigateTo(newPageContent)
                }) {
                    VStack {
                        VStack {
                        Image(systemName: "arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Image(systemName: "ellipsis.rectangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        }.frame(height: min(geometry.size.width, geometry.size.height)/10, alignment: .center)
                        Text("Derive a Secret").multilineTextAlignment(.center).font(.footnote)
                    }.frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                }.if( {
                    switch pageContent {
                    case .Derive : return true
                    default: return false
                    }
                }() ) { $0.colorInvert() }
                Button(action: { navigateTo(.Backup) }, label: {
                    VStack {
                        Image("Backup to DiceKey")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                maxWidth: geometry.size.width * BottomButtonFractionalWidth,
                                maxHeight: min(geometry.size.width, geometry.size.height)/10,
                                alignment: .center
                            )
                        Text("Backup this Key").multilineTextAlignment(.center).font(.footnote)
                    }
                }).frame(width: geometry.size.width * BottomButtonFractionalWidth, alignment: .center)
                .if( pageContent == .Backup ) { $0.colorInvert() }
                Spacer()
            }
        }
        .padding(.bottom, geometry.safeAreaInsets.bottom)
        .padding(.top, 5)
        }
        #if os(iOS)
        return view.background(Color(UIColor.systemFill))
//        .background(
//            NavigationLink(destination: DiceKeyWithDerivedValue(diceKey: diceKey, menuOptionChosen: derivationRecipeMenuOptionChosen), isActive: $shouldNavigateToDiceKeyWithDerivedValue, label: { EmptyView() })
//                .position(x: 0, y: 0).frame(width: 0, height: 0).hidden()
//        )
        #else
        return view
        #endif
    }
}

struct DiceKeyPresent: View {
    @Binding var diceKey: DiceKey {
        mutating didSet {
            _diceKeyState = ObservedObject(initialValue: UnlockedDiceKeyState.forDiceKey(diceKey))
        }
    }
    let onForget: () -> Void

    @State var pageContent: DiceKeyPresentPageContent = .Default
    
    @StateObject var backupDiceKeyState = BackupDiceKeyState()

    @ObservedObject var diceKeyState: UnlockedDiceKeyState

    init(diceKey: Binding<DiceKey>, onForget: @escaping () -> Void) {
        self._diceKey = diceKey
        self.onForget = onForget
        self._diceKeyState = ObservedObject(initialValue: UnlockedDiceKeyState.forDiceKey(diceKey.wrappedValue))
    }

    @State private var navBarHeight: CGFloat = 0

    var storageButton: some View {
        Button(action: { navigate(to: .Save) }) {
            VStack(alignment: .center, spacing: 0) {
                ZStack(alignment: .center, content: {
                    Image("Phonelet")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.navigationForeground)
                        .aspectRatio(contentMode: .fit)
                    if diceKeyState.isDiceKeySaved {
                        Image("DiceKey Icon")
                            .renderingMode(.template)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.navigationForeground)
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(2/3)
                    }
                }).aspectRatio(contentMode: .fit)
                Text(diceKeyState.isDiceKeySaved ? "Saved" : "Save")
            }.frame(maxHeight: navBarHeight)
            .if( pageContent == .Save ) { $0.colorInvert() }
        }
    }

    func navigate(to destination: DiceKeyPresentPageContent) {
           if pageContent == destination {
               pageContent = .Default
           } else {
               self.pageContent = destination
           }
    }

    let defaultContentPadding: CGFloat = 15

    var body: some View {
        let reader = GeometryReader { geometry in
            VStack {
                Spacer()
                switch self.pageContent {
                case .Save: DiceKeyStorageOptions(diceKey: diceKey, done: { navigate(to: .Default) }).padding(.horizontal, defaultContentPadding)
                case .Derive(let derivationRecipeBuilder): DiceKeyWithDerivedValue(diceKey: diceKey, derivationRecipeBuilder: derivationRecipeBuilder)
                case .Backup: BackupDiceKey(onComplete: { navigate(to: .Default) }, diceKey: $diceKey, backupDiceKeyState: backupDiceKeyState)
                case .SeedHardwareKey: SeedHardwareSecurityKey().padding(.horizontal, defaultContentPadding)
                default: DiceKeyView(diceKey: diceKey, showLidTab: true).padding(.horizontal, defaultContentPadding)
                }
                Spacer()
                DiceKeyPresentNavigationFooter(pageContent: pageContent, navigateTo: navigate, geometry: geometry)
            }.ignoresSafeArea(.all, edges: .bottom)
        }
        #if os(iOS)
        return reader.navigationViewStyle(StackNavigationViewStyle())
            .navigationTitle(diceKeyState.nickname)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarDiceKeyStyle()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                    Button(action: {
                        self.onForget()
                    }) {
                        VStack {
                            Image(systemName: "lock").foregroundColor(Color.navigationForeground)
                            Text(diceKeyState.isDiceKeySaved ? "Lock" : "Forget").foregroundColor(Color.navigationForeground)
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    storageButton
                }
            }
            .background(
                NavBarAccessor { navBar in self.navBarHeight = navBar.bounds.height }
            )
        #else
        return reader
        #endif
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
//        }
    }
}

struct DiceKeyPresent_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        NavigationView {
            TestDiceKeyPresent().navigationBarDiceKeyStyle()
        }.previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        #else
        NavigationView {
            TestDiceKeyPresent()
        }
        #endif
//
//        DerivedFromDiceKey(diceKey: diceKey) {
//            Text("Derive a Password, Key, or Secret")
//        }
    }
}
