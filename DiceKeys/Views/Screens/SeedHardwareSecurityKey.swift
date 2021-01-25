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
    let diceKey: DiceKey

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

struct SeedSequenceNumberField: View {
    @Binding var sequenceNumber: Int

    var body: some View {
        HStack {
            Spacer()
            SequenceNumberView(sequenceNumber: $sequenceNumber)
            Spacer(minLength: 30)
            Text("Changing the sequence number changes the seed written to the security key.")
                .foregroundColor(Color.formInstructions)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.01)
                .scaledToFit()
                .lineLimit(4)
            Spacer()
        }
    }
}

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
    
    var keySeedAsHexString: String {
        return keySeedAs32Bytes.reduce("") {$0 + String(format: "%02x", $1)}
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
            return "\(securityKey.product): \(securityKey.serialNumber ?? "unknown serial number")"
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

        VStack(alignment: .center) {
            if (writeToSeedInProgress) {
                Text("Press the button on your security key three times.").font(.headline)
                Text("You have \(secondsLeft) seconds to do so").onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { input in
                    self.secondsLeft = max(self.secondsLeft - 1 , 0)
                }.font(.headline).padding(.top, 20)
            } else if (securityKeys.count == 0) {
                Text("Please connect a SoloKey.")
            } else {
                if let errorMessage = errorMessageIfSeedFailedToWrite {
                    Text(errorMessage)
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.bottom, 20)
                    Divider()
                }
                if let nameOfSecurityKey = nameOfKeyIfSeedWrittenSuccessfully {
                        Text("Successfully wrote to key \(nameOfSecurityKey)")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.bottom, 20)
                    Divider()
                }
                SeedSequenceNumberField(sequenceNumber: $sequenceNumber)
                Divider()
                Text("Internal representation of the recipe used to derive the seed")
                    .font(.title3)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                Text(derivationOptionsJson)
                    .font(Font.system(.footnote, design: .monospaced))
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1).padding(.top, 3)
                Divider()
                Text("The seed to be written to the security key")
                    .font(.title3)
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                Text("\(keySeedAsHexString)")
                    .font(Font.system(.footnote, design: .monospaced))
                    .scaledToFit()
                    .minimumScaleFactor(0.01)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1).padding(.top, 3)
                ForEach(self.securityKeys) { securityKey in
                    Button(
                        action: { write(securityKey: securityKey) },
                        label: {
                            Text("Seed \(securityKey.product) SN#\(securityKey.serialNumber ?? "unknown")")
                        }
                    )
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
