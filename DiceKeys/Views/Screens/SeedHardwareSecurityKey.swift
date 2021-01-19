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
private let soloKeyButtonTimeoutInSeconds: Int = 8
private let buttonTimeoutErrorCode: UInt8 = 0x27

enum WriteSecurityKeySeedState {
    case inProgress
    case success(AttachedHidDevice)
    case error(CtapRequestError)
}

struct SeedHardwareSecurityKey: View {
    let diceKey: DiceKey
    
    @ObservedObject var attachedHidDevicesObj: AttachedHidDevices =
        AttachedHidDevices.singleton
    
    var securityKeys: [AttachedHidDevice] {
        attachedHidDevicesObj.connectedDevices
    }
    
    @State var sequenceNumber: Int = 1
    @State var writeSecurityKeySeedState: WriteSecurityKeySeedState?
    @State var secondsLeft: Int = 0
    
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

    func write(securityKey: AttachedHidDevice) {
        switch writeSecurityKeySeedState {
        case .inProgress: return
        default: break
        }
        self.secondsLeft = soloKeyButtonTimeoutInSeconds
        self.writeSecurityKeySeedState = .inProgress
        securityKey.writeSecurityKeySeed(keySeedAs32Bytes: keySeedAs32Bytes, extState: extState) { result in
            DispatchQueue.main.async {
                print("loadKeySeed result: \(result)")
                switch (result) {
                case .failure(let err):
                    self.writeSecurityKeySeedState = .error(err)
                    switch err {
                    case .errorReturned(let errMessage):
                        print ("Error message: \([UInt8](errMessage))")
                    default: break
                }
                default: self.writeSecurityKeySeedState = .success(securityKey)
                }
            }
        }
    }
    
    var writeToSeedInProgress: Bool {
        switch writeSecurityKeySeedState {
        case .inProgress: return true
        default: return false
        }
    }
    
    var nameOfKeyIfSeedWrittenSuccessfully: String? {
        switch writeSecurityKeySeedState {
        case .success(let securityKey):
            return "Successfully wrote to key \(securityKey.product): \(securityKey.serialNumber ?? "unknown serial number")"
        default: return nil
        }
    }

    var errorMessageIfSeedFailedToWrite: String? {
        switch writeSecurityKeySeedState {
        case .error(let err):
            switch err {
            case .couldNotOpenDevice:
                return "Failed to open a connection to the security key"
            case .invalidSeedLength:
                return "Internal error: invalid seed length."
            case .couldNotGenerateRandomNonce:
                return "Internal error: couldn't generate randomness."
            case .errorReturned(let errMessage):
                if (errMessage.elementsEqual([buttonTimeoutErrorCode])) {
                    return "You didn't press the button in time."
                } else {
                    return "Error #: \(errMessage.reduce("") {$0 + String(format: "%02x", $1)})"
                }
            }
        default: return nil
        }
    }

    var body: some View {

        VStack(alignment: .leading) {
            if (securityKeys.count == 0) {
                Text("Please connect a SoloKey.")
            } else {
                if (writeToSeedInProgress) {
                    Text("Press the button on your security key three times. You have \(secondsLeft) seconds to do so").onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { input in
                        self.secondsLeft = max(self.secondsLeft - 1 , 0)
                    }
                }
                if let errorMessage = errorMessageIfSeedFailedToWrite {
                    Text(errorMessage)
                }
                if let nameOfSecurityKey = nameOfKeyIfSeedWrittenSuccessfully {
                        Text("Successfully wrote to key \(nameOfSecurityKey)")
                }
                Text("Derivation Options Json: \(derivationOptionsJson)")
                Text("Seed: \(keySeedAs32Bytes.reduce("") {$0 + String(format: "%02x", $1)})")
                ForEach(securityKeys) { securityKey in
                    Text("\(securityKey.product): \(securityKey.serialNumber ?? "unknown serial number")")
                    Button(action: { write(securityKey: securityKey) }, label: {
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
