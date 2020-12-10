//
//  DiceKeyWithDerivedValue.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import SwiftUI
import SeededCrypto
import Combine

struct DiceKeyWithDerivedValue: View {
    let diceKey: DiceKey
    @State var derivableName: String?
    @State var iterationString: String = "1"

    var diceKeyState: UnlockedDiceKeyState {
        UnlockedDiceKeyState.forDiceKey(diceKey)
    }

    @State var customDerivationOptionsJson: String = ""
    @State var useCustomDerivationOptions: Bool = false
    @State var iteration: Int = 1

    var derivable: Derivable? {
        get {
            GlobalState.instance.derivables.first(where: { $0.name == derivableName })
        }
    }

    var derivationOptionsJson: String {
        useCustomDerivationOptions ?
            customDerivationOptionsJson :
            derivable?.getDerivationOptionsJson(iteration: iteration) ?? ""
    }

    var derivedPassword: String {
        let derivationOptionsJson = self.derivationOptionsJson
        guard derivationOptionsJson.count > 0 else {
            return ""
        }
        return (try? Password.deriveFromSeed(withSeedString: diceKeyState.diceKey.toSeed(), derivationOptionsJson: derivationOptionsJson).password) ?? ""
    }

    var derivables: [Derivable] {
        GlobalState.instance.derivables
    }

    var derivedValue: String {
        derivedPassword
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                if let derivables = self.derivables {
                    Spacer()
                    if derivables.count > 0 {
                        Menu {
                            ForEach(derivables) { derivable in
                                Button(derivable.name) { derivableName = derivable.name }
                            }
                        } label: { VStack {
                            Image(systemName: "arrow.down")
                            Image(systemName: "ellipsis.rectangle.fill")
                            Text(derivableName ?? "Derive...")
                        } }
                    }
                }
                Spacer()
                TextField("Iteration", text: $iterationString).font(.title)
                    .keyboardType(.numberPad)
                    .onReceive(Just(iterationString)) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                self.iterationString = filtered
                            }
                    }.multilineTextAlignment(.center).frame(maxWidth: 30)
                VStack {
                    Button(action: { iterationString = String((Int(iterationString) ?? 0) + 1) },
                        label: {
                            Image(systemName: "arrow.up.square")
//                                .scaleEffect(2)
//                                .aspectRatio(contentMode: .fit)
                        }
                    ).padding(.bottom, 3)
                    Button(action: { iterationString = String(max(1, (Int(iterationString) ?? 0) - 1)) },
                        label: {
                            Image(systemName: "arrow.down.square")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
                        }
                    )
                }.aspectRatio(contentMode: .fit)
                Spacer()
            }
            Spacer()
            DerivedFromDiceKey(diceKey: diceKeyState.diceKey) {
                VStack {
                    Text(derivedValue).multilineTextAlignment(.center)
                }.padding(.horizontal, 10)
            }
            if derivedValue != "" {
                Button("Copy") { UIPasteboard.general.string = derivedValue }
            }
            Spacer()
            Text(derivationOptionsJson)
            Spacer()
        }
    }
}

struct DiceKeyWithDerivedValue_Test: View {
    var body: some View {
        DiceKeyWithDerivedValue(diceKey: DiceKey.createFromRandom())
    }
}

struct DiceKeyWithDerivedValue_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyWithDerivedValue_Test()
            .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
    }
}
