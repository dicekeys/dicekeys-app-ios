//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
    @State var diceKey: DiceKey?
    @ObservedObject var globalState = GlobalState.instance
    @State var showAssembleInstructions = false

    var knownDiceKeysState: [KnownDiceKeyState] {
        GlobalState.instance.knownDiceKeys.map { KnownDiceKeyState($0) }.filter {
            $0.isDiceKeySaved
        }
    }

    @State var scanDiceKeyIsActive: Bool = false

    var hiddenNavigationLinkToScanDiceKey: some View {
#if os(iOS)
        return NavigationLink(
            destination: ScanDiceKey(
                onDiceKeyRead: { diceKey in
                    self.diceKey = diceKey
                    scanDiceKeyIsActive = false
                }).navigationBarTitleDisplayMode(.inline)
                .navigationBarDiceKeyStyle(),
            isActive: $scanDiceKeyIsActive,
            label: { EmptyView() }
        )
        .frame(width: 0, height: 0)
        .position(x: 0, y: 0)
        .hidden()
#else
        return NavigationLink(
            destination: ScanDiceKey(
                onDiceKeyRead: { diceKey in
                    self.diceKey = diceKey
                    scanDiceKeyIsActive = false
                }),
            isActive: $scanDiceKeyIsActive,
            label: { EmptyView() }
        )
        .frame(width: 0, height: 0)
        .position(x: 0, y: 0)
        .hidden()
#endif
    }

    var hiddenNavigationLinkToDiceKeyPresent: some View {
        NavigationLink(
            destination: DiceKeyPresent(
                diceKey: Binding<DiceKey>(
                    get: { self.diceKey ?? DiceKey.Example },
                    set: { self.diceKey = $0 }
                ),
                onForget: {
                    if let diceKey = diceKey {
                        UnlockedDiceKeyState.forget(diceKey: diceKey)
                    }
                    self.diceKey = nil
                }
            ),
            isActive: Binding<Bool>(
                get: { diceKey != nil },
                set: { _ in }
            ),
            label: { EmptyView() }
        )
        .frame(width: 0, height: 0)
        .position(x: 0, y: 0)
        .hidden()
    }
    
    #if os(iOS)
    let screenShorterSide = UIScreen.main.bounds.size.shorterSide
    let screenHeight = UIScreen.main.bounds.size.height
    #else
    let screenShorterSide:CGFloat = NSScreen.main!.frame.height / 5.0// NSApplication.shared.windows[0].frame.height
    let screenHeight:CGFloat = NSScreen.main!.frame.height / 5.0 // NSApplication.shared.windows[0].frame.height
    #endif

    var body: some View {
        let vstack = VStack {
            Spacer()
            ForEach(knownDiceKeysState) { knownDiceKeyState in
                Button(action: {
                    EncryptedDiceKeyFileAccessor.instance.getDiceKey(fromKeyId: knownDiceKeyState.id, centerFace: knownDiceKeyState.centerFace) { result in
                            switch result {
                            case .success(let diceKey):
                                self.diceKey = diceKey
                            default: ()
                        }
                    }
                }, label: {
                    VStack {
                        if let centerFace = knownDiceKeyState.centerFace {
                            HStack {
                                Spacer()
                                DiceKeyCenterFaceOnlyView(centerFace: centerFace)
                                Spacer()
                            }.frame(
                                maxHeight: screenHeight / 5
                            )
                        }
                        Text("Unlock " + knownDiceKeyState.nickname).font(.title2)
                    }
                })
                Spacer()
            }
            Button(action: { scanDiceKeyIsActive = true }//,
//                       label: {
//                    /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
//                })
//                NavigationLink(
//                    destination: ScanDiceKey(
//                        onDiceKeyRead: { diceKey in
//                            self.diceKey = diceKey
//                        }).navigationBarTitleDisplayMode(.inline)
//                        .navigationBarDiceKeyStyle()
            ) {
                VStack(alignment: .center) {
                    KeyScanningIllustration(.Dice).aspectRatio(contentMode: .fit).frame(maxHeight: 0.3 * screenShorterSide)
                    //Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: UIScreen.main.bounds.size.shorterSide / 4)
                    Text("Read your DiceKey").font(.title2)
                }
            }
            Spacer()
            NavigationLink(
                destination: AssemblyInstructions(onSuccess: { self.diceKey = $0 })) {
                VStack {
                    #if os(iOS)
                    HStack {
                        Spacer()
                        Image("Illustration of shaking bag").resizable().aspectRatio(contentMode: .fit)
                        Spacer(minLength: 20)
                        Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
                        Spacer(minLength: 20)
                        Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
                        Spacer(minLength: 20)
                    }.padding(.horizontal, 20).frame(maxHeight: screenShorterSide / 4)
                    #endif
                    Text("Assemble your First DiceKey").font(.title2)
                }
            }
            Spacer()
            NavigationLink(
                destination: TypeYourDiceKeyView(),
                label: {
                    Text("Type your Dicekey")
                })
            Spacer()
        }.background( ZStack {
            hiddenNavigationLinkToDiceKeyPresent
            hiddenNavigationLinkToScanDiceKey
        })
        #if os(iOS)
        let view = NavigationView {
            vstack.navigationBarTitle("").navigationBarHidden(true)
        }.navigationViewStyle(StackNavigationViewStyle())
        #else
        let view = NavigationView {
            vstack
        }
        #endif
        return view
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(iOS)
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
        #else
        AppMainView().frame(width: 720, height: 600)
        #endif
    }
}
