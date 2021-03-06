//
//  AttachedHidDevices.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/01/18.
//
#if os(macOS)

import Foundation
import IOKit.hid

class AttachedHidDevicesObservable {
    
}

/// This class tracks the list of attached HID (USB/Bluetooth) devices
class AttachedHidDevices: NSObject, ObservableObject {
    var onDeviceAdded: ((AttachedHidDevice) -> Void)?
    var onDeviceRemoved: ((AttachedHidDevice) -> Void)?
        
    @Published var connectedDevicesBySerialNumber: [String: AttachedHidDevice] = [:]
    
    static var singleton = AttachedHidDevices()
    
    var connectedDevices: [AttachedHidDevice] {
        Array(connectedDevicesBySerialNumber.values)
    }
        
    // The callback that handles when an HID device is connected
    func deviceMatchedOrConnectedCallback(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let connectedDevice = AttachedHidDevice(inIOHIDDeviceRef)
        print("Device connected") //  \(inIOHIDDeviceRef.debugDescription)")
//        print("product: \(connectedDevice.product)")
//        print("productId: \(connectedDevice.productId)")
//        print("vendorId: \(connectedDevice.vendorId)")
//        print("manufacturer: \(connectedDevice.manufacturer ?? "")")
//        print("serialNumber: \(connectedDevice.serialNumber ?? "")")
//        print("primaryUsagePage: \(connectedDevice.primaryUsagePage)")
//        print("isFido: \(connectedDevice.isFido)")
//        print("transport: \(connectedDevice.transport ?? "")")
//        print("maxInputReportSize: \(connectedDevice.maxInputReportSize)")
//        print("maxOutputReportSize: \(connectedDevice.maxOutputReportSize)")

        if let serialNumber = connectedDevice.serialNumber {
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.connectedDevicesBySerialNumber[serialNumber] = connectedDevice
                self.onDeviceAdded?(connectedDevice)
            }
        }
    }
    
    // A wrapper for the onDeviceMatchedOrConnected that reconstructs a
    // reference to the class instance and then calls the method on the class
    static let deviceMatchedOrConnectedCallbackWrapper: IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
        let this : AttachedHidDevices = Unmanaged<AttachedHidDevices>.fromOpaque(inContext!).takeUnretainedValue()
        this.deviceMatchedOrConnectedCallback(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
    }
    
    // Called whenever a matching HID device is removed
    func deviceRemovedCallback(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device removed")
        let matchedDevice = AttachedHidDevice(inIOHIDDeviceRef)
        let matchedDevicesSerialNumber = matchedDevice.serialNumber
        if let serialNumber = matchedDevicesSerialNumber {
            DispatchQueue.main.async {
                self.objectWillChange.send()
                self.connectedDevicesBySerialNumber.removeValue(forKey: serialNumber)
                self.onDeviceRemoved?(matchedDevice)
                print("Removed \(serialNumber)")
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceDisconnected"), object: nil, userInfo: ["class": NSStringFromClass(type(of: self))])
    }
    
    // A wrapper for the onDeviceMatchedOrConnected that reconstructs a
    // reference to the class instance and then calls the method on the class
    static let deviceRemovedCallbackWrapper : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
        let this : AttachedHidDevices = Unmanaged<AttachedHidDevices>.fromOpaque(inContext!).takeUnretainedValue()
        this.deviceRemovedCallback(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
    }
    
    override init() {
        super.init()
        DispatchQueue(label: "com.dicekeys.hid-loop", attributes: .concurrent).async {
            // Construct a manager for USB HID devices
            let managerRef: IOHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
            
            // Search for product/vendor IDs that match security keys known to support seeding
            let deviceMatchesAll: CFArray = [
                [kIOHIDProductIDKey: 0x8acf, kIOHIDVendorIDKey: 0x10c4] as CFDictionary,
                [kIOHIDProductIDKey: 0xa2ca, kIOHIDVendorIDKey: 0x483] as CFDictionary
            ] as CFArray
            IOHIDManagerSetDeviceMatchingMultiple(managerRef, deviceMatchesAll)

            // For anyone learning from this code, or debugging the search for devices,
            // replace the above line with the one below to enumerate all HID devices
            //  IOHIDManagerSetDeviceMatching(managerRef, nil as CFDictionary?)
            
            //
            IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            //IOHIDManagerOpen(managerRef, 0)

            // To wireup callbacks to unmanaged code, we'll need a reference to
            // this object (self) that can be passed to unmanaged code.
            let this = Unmanaged.passRetained(self).toOpaque()

            // Wireup the wrappers passing a reference to self as the context
            IOHIDManagerRegisterDeviceMatchingCallback(managerRef, AttachedHidDevices.deviceMatchedOrConnectedCallbackWrapper, this)
            IOHIDManagerRegisterDeviceRemovalCallback(managerRef, AttachedHidDevices.deviceRemovedCallbackWrapper, this)
            
            RunLoop.current.run()
        }
    }
}

#endif
