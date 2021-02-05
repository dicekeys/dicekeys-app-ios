//
//  DiceKeyPresent.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/27.
//

import SwiftUI

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
    
    var navBarContentHeight: CGFloat { geometry.size.height / 12 }
    var navBarImageHeight: CGFloat { navBarContentHeight * 0.75 }

    var body: some View {
        let view = VStack {
        ZStack {
            HStack(alignment: .top) {
                Spacer()
                VStack {
                    Image("USB Key")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture { navigateTo(.SeedHardwareKey) }
                    Text("Seed a SoloKey").multilineTextAlignment(.center).font(.footnote)

                }.frame(width: geometry.size.width * BottomButtonFractionalWidth,
                        height: navBarContentHeight, alignment: .center)
                .onTapGesture {
                    navigateTo(.SeedHardwareKey)
                }
                .if( pageContent == .SeedHardwareKey ) { $0.colorInvert()
                }
                #if os(iOS)
                DerivationRecipeMenu({ newPageContent in
                    navigateTo(newPageContent)
                }) {
                    VStack {
                        Image(systemName: "arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Spacer(minLength: 2)
                        Image(systemName: "ellipsis.rectangle.fill")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Spacer(minLength: 2)
                        Text("Derive a Secret").multilineTextAlignment(.center).font(.footnote)
                    }
                    .foregroundColor(.black)
                }
                .frame(width: geometry.size.width * BottomButtonFractionalWidth,
                       height: navBarContentHeight,
                       alignment: .center)
                .if( {
                    switch pageContent {
                    case .Derive : return true
                    default: return false
                    }
                }() ) { $0.colorInvert() }
                #elseif os(macOS)
                VStack {
                    Image(systemName: "arrow.down")
                        
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Spacer(minLength: 2)
                    Image(systemName: "ellipsis.rectangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Spacer(minLength: 2)
                    DerivationRecipeMenu({ newPageContent in
                        navigateTo(newPageContent)
                    }) {
                        Text("Derive a Secret").multilineTextAlignment(.center).font(.footnote)
                    }
                }.frame(width: geometry.size.width * BottomButtonFractionalWidth,
                        height: navBarContentHeight)
                .if( {
                    switch pageContent {
                    case .Derive : return true
                    default: return false
                    }
                }() ) { $0.colorInvert() }                #endif
//                .frame(width: geometry.size.width * BottomButtonFractionalWidth,
//                       height: geometry.size.height / 12, alignment: .center)

                VStack {
                    Image("Backup to DiceKey")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            maxWidth: geometry.size.width * BottomButtonFractionalWidth,
                            maxHeight: navBarContentHeight,
                            alignment: .center
                        )
                    Text("Backup this Key").multilineTextAlignment(.center).font(.footnote)
                }.frame(width: geometry.size.width * BottomButtonFractionalWidth, height: navBarContentHeight, alignment: .center)
                .onTapGesture { navigateTo(.Backup) }
                .if( pageContent == .Backup ) { $0.colorInvert() }
                Spacer()
            }
        }
        .padding(.bottom, geometry.safeAreaInsets.bottom)
        .padding(.top, 5)
        }
        #if os(iOS)
        return view.background(Color(UIColor.systemFill))
        #else
        return view
        #endif
    }
}

struct DiceKeyPresent: View {
    @ObservedObject var diceKeyState: UnlockedDiceKeyState
    let onForget: () -> Void

    @State var pageContent: DiceKeyPresentPageContent = .Default
    
    @StateObject var backupDiceKeyState = BackupDiceKeyState()

    @State private var navBarHeight: CGFloat = 0
    
    private var deviceImageName: String {
        #if os(iOS)
        return "Phonelet"
        #else
        return "Laptop"
        #endif
    }
    
    private var deviceImageColor: Color {
        #if os(iOS)
        return Color.navigationForeground
        #else
        return Color.black
        #endif
    }
    
    var storageButton: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .center, content: {
                Image(deviceImageName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(deviceImageColor)
                    .aspectRatio(contentMode: .fit)
                if diceKeyState.isDiceKeySaved {
                    Image("DiceKey Icon")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color.navigationForeground)
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(2/3)
                }
            }).aspectRatio(contentMode: .fit)
            .frame(maxHeight: 30)
            Text(diceKeyState.isDiceKeySaved ? "Saved" : "Save").foregroundColor(Color.navigationForeground)
        }
        .if( pageContent == .Save ) { $0.colorInvert() }
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
        WithNavigationHeader(header: {
            HStack {
                VStack {
                    Image(systemName: "lock").foregroundColor(Color.navigationForeground)
                    Text(diceKeyState.isDiceKeySaved ? "Lock" : "Forget").foregroundColor(Color.navigationForeground)
                }.padding(10)
                .onTapGesture {
                    GlobalState.instance.topLevelNavigation = .nowhere
                }
                Spacer()
                Text("\(diceKeyState.nickname)")
                    .font(.title)
                    .minimumScaleFactor(0.01)
                    .scaledToFit()
                    .lineLimit(1)
                    .foregroundColor(Color.navigationForeground)
                Spacer()
                storageButton
                .padding(10)
                .onTapGesture {
                    navigate(to: .Save)
                }
            }
        }) { geometry in
            VStack {
                Spacer()
                if let diceKey = diceKeyState.diceKey {
                    switch self.pageContent {
                    case .Save: DiceKeyStorageOptions(diceKey: diceKey, done: { navigate(to: .Default) }).padding(.horizontal, defaultContentPadding)
                    case .Derive(let derivationRecipeBuilder): DiceKeyWithDerivedValue(diceKey: diceKey, derivationRecipeBuilder: derivationRecipeBuilder)
                    case .Backup: BackupDiceKey(
                        onComplete: { navigate(to: .Default) },
                        diceKey: Binding<DiceKey>(get: { () -> DiceKey in
                            GlobalState.instance.diceKeyLoaded ?? DiceKey.Example
                        }, set: {GlobalState.instance.diceKeyLoaded = $0}),
                        backupDiceKeyState: backupDiceKeyState)
                    case .SeedHardwareKey: SeedHardwareSecurityKey(diceKey: diceKey).padding(.horizontal, defaultContentPadding)
                    default: DiceKeyView(diceKey: diceKey, showLidTab: true).padding(.horizontal, defaultContentPadding)
                    }
                    Spacer()
                }
//                Text("--\(geometry.safeAreaInsets.bottom)")
                DiceKeyPresentNavigationFooter(pageContent: pageContent, navigateTo: navigate, geometry: geometry)
            }
        }//.ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TestDiceKeyPresent: View {
//    @State var diceKeyState: UnlockedDiceKeyState = UnlockedDiceKeyState(DiceKey.createFromRandom())
    @State var diceKey = DiceKey.createFromRandom()
    @ObservedObject var diceKeyUnlocked = UnlockedDiceKeyState(diceKey: DiceKey.createFromRandom())

    var body: some View {
        DiceKeyPresent(
            diceKeyState: diceKeyUnlocked,
            onForget: {}
        )
    }
}

struct DiceKeyPresent_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        TestDiceKeyPresent()
        .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        #else
        TestDiceKeyPresent()
        #endif
//
//        DerivedFromDiceKey(diceKey: diceKey) {
//            Text("Derive a Password, Key, or Secret")
//        }
    }
}
