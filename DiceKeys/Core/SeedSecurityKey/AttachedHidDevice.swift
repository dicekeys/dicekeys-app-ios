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

#endif
