//
//  DiceKeyStorageOptions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct DiceKeyStorageOptions: View {
    let diceKey: DiceKey

    enum StorageOption: String {
        case StoreNothing
        case StorePublicKeys
        case StoreDiceKey
    }

    @State var storageOption: StorageOption = .StoreNothing
    @State var diceKeyFileName: String?

    func setStorageOption(_ storageOption: StorageOption) {
        let previousStorageOption = self.storageOption

        if previousStorageOption == .StoreDiceKey {
            // erase diceKey
            if let fileName = self.diceKeyFileName {
                _  = EncryptedDiceKeyFileAccessor().delete(fileName: fileName)
            }
            diceKeyFileName = nil
        }

        if previousStorageOption == .StorePublicKeys {
            // erase public keys
        }

        if storageOption == .StoreDiceKey {
            EncryptedDiceKeyFileAccessor().put(diceKey: diceKey) { result in
                switch result {
                case .failure(let error): print(error)
                case .success(let fileName):
                    self.diceKeyFileName = fileName
                    self.storageOption = .StoreDiceKey
                }
            }
        } else {
            self.storageOption = storageOption
        }
    }

    var body: some View {
        VStack {
            Text("Forget after using, keep only public keys, keep nothing")
            Spacer()
            Button(action: { setStorageOption(.StoreNothing) }) {
                Text("Store nothing")
            }.disabled( self.storageOption == .StoreNothing )
            Spacer()
            Button(action: { setStorageOption(.StorePublicKeys) }) {
                Text("Store public keys")
            }.disabled( self.storageOption == .StorePublicKeys )
            Spacer()
            Button(action: { setStorageOption(.StoreDiceKey) }) {
                VStack {
                    Text("Store raw key")
                    if let diceKeyFileName = self.diceKeyFileName {
                        Text("File name: \(diceKeyFileName)")
                    }
                }
            }.disabled( self.storageOption == .StoreDiceKey )
            Spacer()
        }
    }
}

struct DiceKeyStorageOptions_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyStorageOptions(diceKey: DiceKey.createFromRandom())
    }
}
