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
    case Secrets
    case Derive(DerivationRecipeBuilderType)
    case Save
    case Default
}

struct DiceKeyPresentNavigationFooter: View {
    let pageContent: DiceKeyPresentPageContent
    let navigateTo: (DiceKeyPresentPageContent) -> Void
    let geometry: GeometryProxy

    @State private var isBackupActive = false

    var BottomButtonCount: Int = 4
    var BottomButtonFractionalWidth: CGFloat {
        0.9 / CGFloat(BottomButtonCount)
    }
    
    var BottomButtonRealWidth: CGFloat {
        geometry.size.width * BottomButtonFractionalWidth
    }
    
    var navBarContentHeight: CGFloat { geometry.size.height / 12 }
    var navBarImageHeight: CGFloat { navBarContentHeight * 0.75 }

    var body: some View {
        let view = VStack(alignment: .center, spacing: 0) {
        HStack(alignment: .top) {
            Spacer()
            VStack {
                Image("DiceKey Icon")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture { navigateTo(.Default) }
                Text("DiceKey").multilineTextAlignment(.center).font(.footnote)
            }.frame(width: BottomButtonRealWidth,
                    height: navBarContentHeight, alignment: .center)
            .onTapGesture {
                navigateTo(.SeedHardwareKey)
            }
            .if( pageContent == .Default ) { $0.colorInvert() }
            Spacer()
            VStack {
                Image("USB Key")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture { navigateTo(.SeedHardwareKey) }
                Text("SoloKey").multilineTextAlignment(.center).font(.footnote)

            }.frame(width: BottomButtonRealWidth,
                    height: navBarContentHeight, alignment: .center)
            .onTapGesture {
                navigateTo(.SeedHardwareKey)
            }
            .if( pageContent == .SeedHardwareKey ) { $0.colorInvert() }
            // Secrets
            VStack {
                Image("Secret with Arrow")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer(minLength: 2)
                Text("Secrets").multilineTextAlignment(.center).font(.footnote)
            }.frame(width: BottomButtonRealWidth,
                    height: navBarContentHeight, alignment: .center)
            .onTapGesture {
                navigateTo(.Secrets)
            }
            
            .if( pageContent == .Secrets ) { $0.colorInvert() }

            VStack {
                Image("Backup to DiceKey")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        maxWidth: BottomButtonRealWidth,
                        maxHeight: navBarContentHeight,
                        alignment: .center
                    )
                Text("Backup").multilineTextAlignment(.center).font(.footnote)
            }.frame(width: BottomButtonRealWidth, height: navBarContentHeight, alignment: .center)
            .onTapGesture { navigateTo(.Backup) }
            .if( pageContent == .Backup ) { $0.colorInvert() }
            Spacer()
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
    let onComplete: () -> Void
    @ObservedObject var diceKeyMemoryStore: DiceKeyMemoryStore = DiceKeyMemoryStore.singleton

    @State var pageContent: DiceKeyPresentPageContent = .Default
    
    @StateObject var backupDiceKeyState = BackupDiceKeyState()

    @State private var navBarHeight: CGFloat = 0
    
    var diceKey: DiceKey {
        diceKeyMemoryStore.diceKeyLoaded ?? DiceKey.Example
    }

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
                if diceKeyState.isDiceKeyStored {
                    Image("DiceKey Icon")
                        .renderingMode(.template)
                        .resizable()
                        .foregroundColor(Color.navigationForeground)
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(2/3)
                }
            }).aspectRatio(contentMode: .fit)
            .frame(maxHeight: 30)
            Text(diceKeyState.isDiceKeyStored ? "Saved" : "Save").foregroundColor(Color.navigationForeground)
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
                    Image(systemName: "arrow.backward").foregroundColor(Color.navigationForeground)
                    // Text("Back").foregroundColor(Color.navigationForeground)
                    // Text(diceKeyState.isDiceKeySaved ? "Lock" : "Forget").foregroundColor(Color.navigationForeground)
                }.padding(10)
                .onTapGesture {
                    onComplete()
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
            VStack(alignment: .center, spacing: 0) {
                if let diceKey = diceKeyState.diceKey {
                    switch self.pageContent {
                    case .Save:
                        Spacer()
                        DiceKeyStorageOptions(diceKey: diceKey, done: { navigate(to: .Default) }).padding(.horizontal, defaultContentPadding)
                        Spacer()
                    
                    case .Derive(let derivationRecipeBuilder):
                            Spacer()
                            DiceKeyWithDerivedValue(diceKey: diceKey, derivationRecipeBuilder: derivationRecipeBuilder)//.layoutPriority(-1)
                            Spacer()
                case .Backup:
                        Spacer()
                        BackupDiceKey(
                        onComplete: { navigate(to: .Default) },
                        diceKey: Binding<DiceKey>(get: { () -> DiceKey in
                            diceKey
                        }, set: { diceKeyMemoryStore.setDiceKey(diceKey: $0)}),
                        backupDiceKeyState: backupDiceKeyState)
                        Spacer()
                    
                    case .Secrets: SecretsView(navigateTo: navigate)
                    
                case .SeedHardwareKey:
                        Spacer()
                        SeedHardwareSecurityKey(diceKey: diceKey).padding(.horizontal, defaultContentPadding)
                        Spacer()
                    default:
                        Spacer()
                     DiceKeyView(diceKey: diceKey, showLidTab: true, hideFaces: true, withShowDiceLabel: true).padding(.horizontal, defaultContentPadding)
                        Spacer()
                    }
                }
//                Text("--\(geometry.safeAreaInsets.bottom)")
                DiceKeyPresentNavigationFooter(pageContent: pageContent, navigateTo: navigate, geometry: geometry)
                    .layoutPriority(100)
            }
        }.ignoresSafeArea(.keyboard)
        //.ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TestDiceKeyPresent: View {
//    @State var diceKeyState: UnlockedDiceKeyState = UnlockedDiceKeyState(DiceKey.createFromRandom())
    @State var diceKey = DiceKey.createFromRandom()
    @ObservedObject var diceKeyUnlocked = UnlockedDiceKeyState(diceKey: DiceKey.createFromRandom())

    var body: some View {
        DiceKeyPresent(
            diceKeyState: diceKeyUnlocked,
            onComplete: {}
        )
        .environmentObject(DerivationRecipeStore())
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
        //  , topLevelNavigationState: <#TopLevelNavigationState#>      }
    }
}
