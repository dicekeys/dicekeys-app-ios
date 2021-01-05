//
//  Seed.swift
//  DiceKeys (iOS)
//
//  Created by Stuart Schechter on 2021/01/03.
//
//  Using lessons learned about writing Swift USB code from:
//    https://github.com/dwaite/Swift-HID-Example/blob/master/Swift-HID-Example/Blink1.swift

import Foundation
import IOKit.hid
import Combine


private let hidPacketLengthInBytes: Int = 64

enum CTAPCommand: UInt8 {
    case MSG = 0x03
    case INIT = 0x06
    case WINK = 0x08
    case ERROR = 0x3F
    case LOADKEYSEED = 0x62
}

class AttachedHidDevice {
    let unmanagedDeviceRef: IOHIDDevice

    init (_ unmanagedDeviceRef: IOHIDDevice) {
        self.unmanagedDeviceRef = unmanagedDeviceRef
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
}

class HidPacketReceived {
    let packet: Data
    
    init (_ packet: Data) {
        self.packet = packet
    }
    var headerSizeInBytes: Int {
        isInitializationPacket ? 7 : 5
    }
    var channel: UInt32 {
        UInt32(packet[0]) << 24 |
        UInt32(packet[1]) << 16 |
        UInt32(packet[2]) <<  8 |
        UInt32(packet[3])
    }
    var commandByte: UInt8 {
        packet[4]
    }
    var isInitializationPacket: Bool {
        (commandByte & 0x80) != 0
    }
    var command: CTAPCommand {
        CTAPCommand(rawValue: packet[4] & 0x7f) ?? CTAPCommand.ERROR
    }
    var length: UInt16 {
        isInitializationPacket ?
            (UInt16(packet[5]) << 8) | UInt16(packet[6]) :
            UInt16(hidPacketLengthInBytes - headerSizeInBytes)
    }
    var message: Data {
        Data(packet.suffix(from: headerSizeInBytes).prefix(Int(length)))
    }
}

class HidInitResponseMessage {
    let message: Data
    
    init(_ message: Data) {
        self.message = message
    }
    
    // DATA    8-byte nonce
    var nonce: Data {
        Data(message.prefix(8))
    }
//    var nonceBytes: [UInt8] {
//        Array(nonce)
//    }

    // DATA+8    4-byte channel ID
    var channelCreated: UInt32 {
        UInt32(message[8]) << 24 |
        UInt32(message[9]) << 16 |
        UInt32(message[10]) << 8 |
        UInt32(message[11])
    }

    // DATA+12    CTAPHID protocol version identifier
    var ctapProtocolVersionIdentifier: UInt8 { message[12] }
    // DATA+13    Major device version number
    var majorDeviceVersionNumber: UInt8 { message[13] }
    // DATA+14    Minor device version number
    var minorDeviceVersionNumber: UInt8 { message[14] }
    // DATA+15    Build device version number
    var buildDeviceVersionNumber: UInt8 { message[15] }
    // DATA+16    Capabilities flags
    var capabilitiesFlags: UInt8 { message[16] }
}

enum CTAPRequestError: Error {
    case couldNotOpenDevice
    case invalidSeedLength
    case couldNotGenerateRandomNonce
    case errorReturned(Data)
}

class HidDeviceConnection {
    let device: AttachedHidDevice
    static let maxReportSize: Int = 64
    let report = UnsafeMutablePointer<UInt8>.allocate(capacity: HidDeviceConnection.maxReportSize)
    var callbacksForCreateChannelIndexByNonce: [Data: (Result<UInt32, CTAPRequestError>) -> Void] = [:]
    var callbacksForLoadKeySeedIndexByChannel: [UInt32: (Result<Void,CTAPRequestError>) -> Void] = [:]
    
    init(_ device: AttachedHidDevice) {
        self.device = device
        
        let this = Unmanaged.passRetained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device.unmanagedDeviceRef, report, HidDeviceConnection.maxReportSize, receiveHidMessageWrapper, this)
        
        guard IOHIDDeviceOpen(device.unmanagedDeviceRef, IOOptionBits(kIOHIDOptionsTypeSeizeDevice)) == kIOReturnSuccess else {
            print("Couldn't open HID device")
            return
        }
    }
    
    
    func onReceiveHidMessage(_ packet: HidPacketReceived) {
        print("Read from channel \(String(format:"%02X", packet.channel)) with command \(packet.command) and message \([UInt8](packet.message))")
        if (packet.command == CTAPCommand.ERROR) {
            if let callback = callbacksForLoadKeySeedIndexByChannel[packet.channel] {
                callbacksForLoadKeySeedIndexByChannel.removeValue(forKey: packet.channel)
                callback(Result.failure(.errorReturned(packet.message)))
            }
        } else if (packet.isInitializationPacket && packet.command == CTAPCommand.INIT) {
            let initResponse = HidInitResponseMessage(packet.message)
            if let callback = callbacksForCreateChannelIndexByNonce[initResponse.nonce] {
                callbacksForCreateChannelIndexByNonce.removeValue(forKey: initResponse.nonce)
                callback(.success(initResponse.channelCreated))
            }
        } else if (packet.isInitializationPacket && packet.command == CTAPCommand.LOADKEYSEED) {
            if let callback = callbacksForLoadKeySeedIndexByChannel[packet.channel] {
                callbacksForLoadKeySeedIndexByChannel.removeValue(forKey: packet.channel)
                callback(Result.success(()))
            }
        }
    }
    
    func receiveHidMessage(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        onReceiveHidMessage(HidPacketReceived(Data(bytes: report, count: reportLength)))
    }
    private let receiveHidMessageWrapper : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
        let this: HidDeviceConnection = Unmanaged<HidDeviceConnection>.fromOpaque(inContext!).takeUnretainedValue()
        this.receiveHidMessage(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
    }
    
    func sendHidMessage(_ data: Data) -> IOReturn {
        if (data.count > HidDeviceConnection.maxReportSize) {
            print("output data too large for USB report")
            return IOReturn(0)
        }
        let reportId : CFIndex = CFIndex(data[0])
        print("Sending output: \([UInt8](data))")
        return IOHIDDeviceSetReport(device.unmanagedDeviceRef, kIOHIDReportTypeOutput, reportId, [UInt8](data), data.count)
    }
    
    func createChannel(callback: @escaping (Result<UInt32, CTAPRequestError>) -> Void) {
        var channelCreationNonce = Data(count: 8)
        let result = channelCreationNonce.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 8, $0)
        }
        if result != errSecSuccess {
            callback(.failure(CTAPRequestError.couldNotGenerateRandomNonce))
        }
        callbacksForCreateChannelIndexByNonce[channelCreationNonce] = callback
        sendCtapHidMessage(channel: 0xffffffff, command: CTAPCommand.INIT.rawValue, data: channelCreationNonce)
        
        print("Sent channel request with nonce \([UInt8](channelCreationNonce))")
    }
    
    func writeKeySeed(callback: @escaping (UInt32?, CTAPRequestError?) -> Void) {
        
    }

    func sendLoadKeySeed(
        channel: UInt32,
        keySeedAs32Bytes: Data,
        extState: Data = Data(),
        commandVersion: UInt8 = 1,
        callback: @escaping (Result<Void, CTAPRequestError>) -> Void
    ) {
        var message = Data()
        message.append(commandVersion)
        message.append(keySeedAs32Bytes)
        message.append(extState)
        guard keySeedAs32Bytes.count == 32 else {
            callback(.failure(.invalidSeedLength))
            return
        }
        
        callbacksForLoadKeySeedIndexByChannel[channel] = callback
        let sendResult = sendCtapHidMessage(channel: channel, command: CTAPCommand.LOADKEYSEED.rawValue, data: message)
    }
    
    func loadKeySeed(
        keySeedAs32Bytes: Data,
        extState: Data = Data(),
        commandVersion: UInt8 = 1,
        callback: @escaping (Result<Void, CTAPRequestError>) -> Void
    ) {
        createChannel(callback: { (result: Result<UInt32, CTAPRequestError>) in
            switch (result) {
            case .failure(let err): callback(.failure(err))
            case .success(let channel):
                self.sendLoadKeySeed(channel: channel, keySeedAs32Bytes: keySeedAs32Bytes, extState: extState, commandVersion: commandVersion, callback: callback)
            }
        })
    }

    private let hidInitializationPacketHeaderSize: Int = 7
    private var hidInitializationPacketContentSize: Int { hidPacketLengthInBytes - hidInitializationPacketHeaderSize }
    
    private let hidContinuationPacketHeaderSize: Int = 5
    private var hidContinuationPacketContentSize: Int { hidPacketLengthInBytes - hidContinuationPacketHeaderSize }


    func sendCtapHidMessage(channel: UInt32, command: UInt8, data: Data) {
        /*
         *            INITIALIZATION PACKET
         *            Offset   Length    Mnemonic    Description
         *            0        4         CID         Channel identifier
         *            4        1         CMD         Command identifier (bit 7 always set)
         *            5        1         BCNTH       High part of payload length
         *            6        1         BCNTL       Low part of payload length
         *            7        (s - 7)   DATA        Payload data (s is equal to the fixed packet size)
         */
        let lengthUInt16 = UInt16(min(data.count, hidInitializationPacketContentSize))
        var initializationPacket = Data()
        initializationPacket.append(contentsOf: withUnsafeBytes(of: channel.bigEndian, Array.init))
        initializationPacket.append(command | UInt8(0x80))
        initializationPacket.append(UInt8(lengthUInt16 >> 8))
        initializationPacket.append(UInt8(lengthUInt16 & 0xff))
        initializationPacket.append(data.prefix(hidInitializationPacketContentSize))
        // Pad with 0 bytes until the packet is 64 bytes long
        initializationPacket.append(contentsOf: Array(repeating: UInt8(0), count: hidPacketLengthInBytes - (initializationPacket.count)))
        let initResult = sendHidMessage(initializationPacket)
        var remainingData = data.suffix(from: min(data.count, hidInitializationPacketContentSize))
        var packetSequenceByte: UInt8 = 0
        while(remainingData.count > 0 && packetSequenceByte < 0x80) {
            /**
             *  CONTINUATION PACKET
             *  Offset    Length    Mnemonic  Description
             *  0         4         CID       Channel identifier
             *  4         1         SEQ       Packet sequence 0x00..0x7f (bit 7 always cleared)
             *  5         (s - 5)   DATA      Payload data (s is equal to the fixed packet size)
             */
            var continuationPacket = Data()
            continuationPacket.append(contentsOf: withUnsafeBytes(of: channel.bigEndian, Array.init))
            continuationPacket.append(packetSequenceByte)
            packetSequenceByte += 1
            continuationPacket.append(remainingData.prefix(hidContinuationPacketContentSize))
            // Pad with 0 bytes until the packet is 64 bytes long
            continuationPacket.append(contentsOf: Array(repeating: UInt8(0), count: hidPacketLengthInBytes - (continuationPacket.count)))
            remainingData = data.suffix(from: min(remainingData.count, hidContinuationPacketContentSize))
            let continuationResult = sendHidMessage(continuationPacket)
        }
    }
}

class AttachedHidDevices : NSObject {
    var connectedDevicesBySerialNumber: [String: AttachedHidDevice] = [:]
    
    var connectedDevices: [AttachedHidDevice] {
        Array(connectedDevicesBySerialNumber.values)
    }
        
    // The callback that handles when an HID device is connected
    func onDeviceMatchedOrConnected(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let connectedDevice = AttachedHidDevice(inIOHIDDeviceRef)
        print("Device connected") //  \(inIOHIDDeviceRef.debugDescription)")
        print("product: \(connectedDevice.product)")
        print("productId: \(connectedDevice.productId)")
        print("vendorId: \(connectedDevice.vendorId)")
        print("manufacturer: \(connectedDevice.manufacturer ?? "")")
        print("serialNumber: \(connectedDevice.serialNumber ?? "")")
        print("primaryUsagePage: \(connectedDevice.primaryUsagePage)")
        print("isFido: \(connectedDevice.isFido)")
        print("transport: \(connectedDevice.transport ?? "")")
        print("maxInputReportSize: \(connectedDevice.maxInputReportSize)")
        print("maxOutputReportSize: \(connectedDevice.maxOutputReportSize)")

        if let serialNumber = connectedDevice.serialNumber {
            connectedDevicesBySerialNumber[serialNumber] = connectedDevice
            
            let connection = HidDeviceConnection(connectedDevice)
            var testSeed = Data(count: 32)
            let result = testSeed.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, 32, $0)
            }
            if result != errSecSuccess {
                print("Problem generating random bytes")
                return
            }
            connection.loadKeySeed(keySeedAs32Bytes: testSeed, extState: Data()) { result in
                print("loadKeySeed result: \(result)")
                switch (result) {
                case .failure(let err):
                    switch err {
                    case .errorReturned(let errMessage):
                        print ("Error message: \([UInt8](errMessage))")
                    default: break
                }
                default: break
                }
            }
        }
    }
    
    // A wrapper for the onDeviceMatchedOrConnected that reconstructs a
    // reference to the class instance and then calls the method on the class
    static let onDeviceMatchedOrConnectedWrapper: IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
        let this : AttachedHidDevices = Unmanaged<AttachedHidDevices>.fromOpaque(inContext!).takeUnretainedValue()
        this.onDeviceMatchedOrConnected(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
    }
    
    // Called whenever a matching HID device is removed
    func onDeviceRemoved(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device removed")
        let matchedDevicesSerialNumber = AttachedHidDevice(inIOHIDDeviceRef).serialNumber
        if let serialNumber = matchedDevicesSerialNumber {
            connectedDevicesBySerialNumber.removeValue(forKey: serialNumber)
            print("Removed \(serialNumber)")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceDisconnected"), object: nil, userInfo: ["class": NSStringFromClass(type(of: self))])
    }
    
    // A wrapper for the onDeviceMatchedOrConnected that reconstructs a
    // reference to the class instance and then calls the method on the class
    static let onDeviceRemovedWrapper : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
        let this : AttachedHidDevices = Unmanaged<AttachedHidDevices>.fromOpaque(inContext!).takeUnretainedValue()
        this.onDeviceRemoved(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
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
            IOHIDManagerOpen(managerRef, 0)

            // To wireup callbacks to unmanaged code, we'll need a reference to
            // this object (self) that can be passed to unmanaged code.
            let this = Unmanaged.passRetained(self).toOpaque()

            // Wireup the wrappers passing a reference to self as the context
            IOHIDManagerRegisterDeviceMatchingCallback(managerRef, AttachedHidDevices.onDeviceMatchedOrConnectedWrapper, this)
            IOHIDManagerRegisterDeviceRemovalCallback(managerRef, AttachedHidDevices.onDeviceRemovedWrapper, this)
            
            RunLoop.current.run()
        }
    }

}
