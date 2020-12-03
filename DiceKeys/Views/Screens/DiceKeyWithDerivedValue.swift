//
//  DiceKeyWithDerivedValue.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import SwiftUI
import SeededCrypto

struct DiceKeyWithDerivedValue: View {
    @Binding var derivableName: String?
    @ObservedObject var diceKeyState: DiceKeyState

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
        return (try? Password.deriveFromSeed(withSeedString: diceKeyState.diceKey!.toSeed(), derivationOptionsJson: derivationOptionsJson).password) ?? ""
    }

    var derivables: [Derivable] {
        GlobalState.instance.derivables
    }

    var derivedValue: String {
        derivedPassword
    }

    var body: some View {
        VStack {
            Spacer()
            DerivedFromDiceKey(diceKey: diceKeyState.diceKey!) {
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
            if let derivables = self.derivables {
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
        }
    }
}

struct DiceKeyWithDerivedValue_Test: View {
    @State var destinationName: String? = "Microsoft"

    var body: some View {
        DiceKeyWithDerivedValue(derivableName: $destinationName, diceKeyState: DiceKeyState(DiceKey.createFromRandom()))
    }
}

struct DiceKeyWithDerivedValue_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyWithDerivedValue_Test()
    }
}
