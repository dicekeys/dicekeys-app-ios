//
//  AttachedHidDevice.swift
//  DiceKeys (macOS)
//
//  Created by Stuart Schechter on 2021/01/05.
//
#if os(macOS)

import Foundation
import IOKit.hid


/// An abstraction of an HID device, which includes the low-level reference pointer and convenience accessors that retrieve information about the device
class AttachedHidDevice: Identifiable {
    let unmanagedDeviceRef: IOHIDDevice

    init (_ unmanagedDeviceRef: IOHIDDevice) {
        self.unmanagedDeviceRef = unmanagedDeviceRef
    }
    
    var id: String {
        return serialNumber ?? product
    }
    
    var product: String {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDProductKey as CFString) as! CFString as String
    }
    var productId: Int {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDProductIDKey as CFString) as! CFNumber as! Int
    }
    var vendorId: Int {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDVendorIDKey as CFString) as! CFNumber as! Int
    }
    var manufacturer: String? {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDManufacturerKey as CFString) as! CFString? as String?
    }
    var serialNumber: String? {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDSerialNumberKey as CFString) as! CFString? as String?
    }
    var primaryUsagePage: Int {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDPrimaryUsagePageKey as CFString) as! CFNumber as! Int
    }
    var transport: String? {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDTransportKey as CFString) as! CFString? as String?
    }
    var maxInputReportSize: Int {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDMaxInputReportSizeKey as CFString) as! CFNumber as! Int
    }
    var maxOutputReportSize: Int {
        IOHIDDeviceGetProperty(unmanagedDeviceRef, kIOHIDMaxOutputReportSizeKey as CFString) as! CFNumber as! Int
    }

    var isFido: Bool {
        primaryUsagePage == 0xf1d0
    }
    
    func writeSecurityKeySeed(
        keySeedAs32Bytes: Data,
        extState: Data = Data(),
        callback: @escaping (Result<Void, CtapRequestError>) -> Void
    ) {
        CtapHidConnection(self).writeSecurityKeySeed(keySeedAs32Bytes: keySeedAs32Bytes, extState: Data(), callback: callback)
    }
    
}

//func seedSecurityKey(connectedDevice: AttachedHidDevice, keySeedAs32Bytes: Data, extState: Data = Data()) {
//    let connection = CtapHidConnection(connectedDevice)
//    connection.loadKeySeed(keySeedAs32Bytes: keySeedAs32Bytes, extState: Data()) { result in
//        print("loadKeySeed result: \(result)")
//        switch (result) {
//        case .failure(let err):
//            switch err {
//            case .errorReturned(let errMessage):
//                print ("Error message: \([UInt8](errMessage))")
//            default: break
//        }
//        default: break
//        }
//    }
//}
//
//func testSeedDevice(connectedDevice: AttachedHidDevice) {
//    var testSeed = Data(count: 32)
//    let result = testSeed.withUnsafeMutableBytes {
//        SecRandomCopyBytes(kSecRandomDefault, 32, $0)
//    }
//    if result != errSecSuccess {
//        print("Problem generating random bytes")
//        return
//    }
//    seedSecurityKey(connectedDevice: connectedDevice, keySeedAs32Bytes: testSeed)
//}

#endif
