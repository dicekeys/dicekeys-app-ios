//
//  SeedHardwareSecurityKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI
import SeededCrypto

#if os(iOS)
struct SeedHardwareSecurityKey: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Apple prevents apps on iPhones and iPads from writing to USB devices.").font(.title)
            
            Text("To seed a SoloKey, you will need to use this app on a Mac, Android device, or PC.").font(.title).padding(.top, 10)
        }
    }
}
#elseif os(macOS)
struct SeedHardwareSecurityKey: View {
    let diceKey: DiceKey
    
    @ObservedObject var attachedHidDevicesObj: AttachedHidDevices =
        AttachedHidDevices.singleton
    
    var securityKeys: [AttachedHidDevice] {
        attachedHidDevicesObj.connectedDevices
    }
    
    @State var sequenceNumber: Int = 1
    
    let baseDerivationOptionsJson = "{\"purpose\": \"seedSecurityKey\"}"

    var derivationOptionsJson: String {
        addSequenceNumberToDerivationOptionsJson(baseDerivationOptionsJson, sequenceNumber: sequenceNumber)
    }
    
    var extState: Data {
        var sequenceNumberAsSingleByteArray = Data()
        sequenceNumberAsSingleByteArray.append(UInt8(sequenceNumber & 0xff))
        return sequenceNumberAsSingleByteArray
    }
    
    var keySeedAs32Bytes: Data {
        return try! SeededCrypto.Secret.deriveFromSeed(withSeedString: diceKey.toSeed(), derivationOptionsJson: derivationOptionsJson).secretBytes()
    }

    func write(device: AttachedHidDevice) {
        seedSecurityKey(connectedDevice: device, keySeedAs32Bytes: keySeedAs32Bytes, extState: extState)
    }

    var body: some View {
        
        VStack(alignment: .leading) {
            if (securityKeys.count == 0) {
                Text("No compatible security keys connected.")
            } else {
                ForEach(securityKeys) { securityKey in
                    Text("\(securityKey.product): \(securityKey.serialNumber ?? "unknown serial number")")
                    Button(action: { write(device: securityKey) }, label: {
                        Text("Seed")
                    })
                }
            }
        }
    }
}
#endif

struct SeedHardwareSecurityKey_Previews: PreviewProvider {
    static var previews: some View {
        SeedHardwareSecurityKey(diceKey: DiceKey.createFromRandom())
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
