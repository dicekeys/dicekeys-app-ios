//
//  AppMainView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct AppMainView: View {
    // Note: Navigation bar styling is controlled by the UINavigationBarController
    // extension in the Extensions directory

//    @State var diceKey: DiceKey?
    @State var diceKey: DiceKey?
//    @State var diceKeyState: UnlockedDiceKeyState?
//
//    private func getGradientImage(forBounds: CGRect) -> UIImage? {
//        let gradient = CAGradientLayer()
//
//        gradient.frame = bounds
//        gradient.colors = [UIColor.systemBlue.cgColor, UIColor.lighterBlue.cgColor]
//        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
//        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
//
//        UIGraphicsBeginImageContext(gradient.frame.size)
//        defer {
//            UIGraphicsEndImageContext()
//        }
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        gradient.render(in: context)
//        gradientImage = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
//        return gradientImage
//    }
//
//    init() {
//        let navigationBar = UINavigationBar.appearance()
//
//        // navigationBar.backgroundColor = .systemBlue
//        if let image = getImageFrom(gradientLayer: gradient) {
//            navigationBar.setBackground(forBounds: UIBarMetrics.compact)
//            navigationBar.setBackgroundImage(image, for: UIBarMetrics.)
//            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.DiceKeysNavigationForeground]
//            navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.DiceKeysNavigationForeground]
//            navigationBar.tintColor = UIColor.white
//        }
//        
//        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.DiceKeysNavigationForeground]
//        navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.DiceKeysNavigationForeground]
//        navigationBar.tintColor = UIColor.white
//        
//        UINavigationBar.appearance().backgroundImage(for: <#T##UIBarMetrics#>)
//    }

    var knownDiceKeysState: [KnownDiceKeyState] {
        GlobalState.instance.knownDiceKeys.map { KnownDiceKeyState($0) }.filter { $0.isDiceKeyStored }
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
                set: { shouldBeActive in
                    if !shouldBeActive {
                        self.diceKey = nil
                    }
                }
            ),
            label: { EmptyView() }
        )
        .frame(width: 0, height: 0)
        .position(x: 0, y: 0)
        .hidden()
    }

    var body: some View {
        NavigationView {
            VStack {
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
                                    maxHeight: UIScreen.main.bounds.size.height / 5
                                )
                            }
                            Text("Unlock " + knownDiceKeyState.nickname).font(.title2)
                        }
                    })
                    Spacer()
                }
                NavigationLink(
                    destination: ScanDiceKey(
                        onDiceKeyRead: { diceKey in
                            self.diceKey = diceKey
                        }).navigationBarTitleDisplayMode(.inline)
                        .navigationBarDiceKeyStyle()
                ) {
                    VStack(alignment: .center) {
                        KeyScanningIllustration(.Dice).aspectRatio(contentMode: .fit).frame(maxHeight: 0.3 * UIScreen.main.bounds.size.shorterSide)
                        //Image("Scanning Side View").resizable().aspectRatio(contentMode: .fit).frame(maxHeight: UIScreen.main.bounds.size.shorterSide / 4)
                        Text("Read your DiceKey").font(.title2)
                    }
                }
                Spacer()
                NavigationLink(
                    destination: AssemblyInstructions(onSuccess: { self.diceKey = $0 })) {
                    VStack {
                        HStack {
                            Spacer()
                            Image("Illustration of shaking bag").resizable().aspectRatio(contentMode: .fit)
                            Spacer(minLength: 20)
                            Image("Box Bottom After Roll").resizable().aspectRatio(contentMode: .fit)
                            Spacer(minLength: 20)
                            Image("Seal Box").resizable().aspectRatio(contentMode: .fit)
                            Spacer(minLength: 20)
                        }.padding(.horizontal, 20).frame(maxHeight: UIScreen.main.bounds.size.shorterSide / 4)
                        Text("Assemble your First DiceKey").font(.title2)
                    }
                }
                Spacer()
            }.background( ZStack {
                hiddenNavigationLinkToDiceKeyPresent
                    .frame(width: 0, height: 0)
                    .position(x: 0, y: 0)
                    .hidden()
            })
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
struct AppMainView_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
//        AppMainView().previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))
    }
}
