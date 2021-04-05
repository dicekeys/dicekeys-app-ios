//
//  main.swift
//  DiceKeys (Terminal)
//
//  Created by bakhtiyor on 05/04/21.
//

import Foundation

let arguments = CommandLine.arguments
if arguments.count >= 2 {
  let seed = arguments[1]
  if let seedAs32bytes = seed.data(using: .hexadecimal), seedAs32bytes.count == 32 {
    print("Seed set to \(seed).")
    let securityKeys: [AttachedHidDevice] = AttachedHidDevices.singleton.connectedDevices
    if securityKeys.count > 0 {
      let securityKey = securityKeys[0]
      let semaphore = DispatchSemaphore(value: 0)
      
      securityKey.writeSecurityKeySeed(keySeedAs32Bytes: seedAs32bytes) { (result) in
        switch (result) {
        case .failure(let err):
          switch err {
          case .couldNotOpenDevice:
            print("Error: could not open device.")
          case .invalidSeedLength:
            print("Error: invalid seed length.")
          case .couldNotGenerateRandomNonce:
            print("Error: could not generate random nonce.")
          case .errorReturned(let errMessage):
            print("Error: code \([UInt8](errMessage)).")
          }
        default: print("Success.")
        }
        semaphore.signal()
      }
      
      _ = semaphore.wait(timeout: .distantFuture)
    } else {
      print("No devices.")
    }
  } else {
    print("Input data should be 32 bytes as a hexademical digit.")
  }
} else {
  print("No seed provided.")
}

// ----------------------------------------------------------------

extension String {
  enum ExtendedEncoding {
    case hexadecimal
  }
  
  func data(using encoding:ExtendedEncoding) -> Data? {
    let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)
    
    guard hexStr.count % 2 == 0 else { return nil }
    
    var newData = Data(capacity: hexStr.count/2)
    
    var indexIsEven = true
    for i in hexStr.indices {
      if indexIsEven {
        let byteRange = i...hexStr.index(after: i)
        guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
        newData.append(byte)
      }
      indexIsEven.toggle()
    }
    return newData
  }
}
