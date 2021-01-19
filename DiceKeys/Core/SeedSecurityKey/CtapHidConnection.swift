//
//  Seed.swift
//  DiceKeys (macOS)
//
//  Created by Stuart Schechter on 2021/01/03.
//
//  Using lessons learned about writing Swift USB code from:
//    https://github.com/dwaite/Swift-HID-Example/blob/master/Swift-HID-Example/Blink1.swift

#if os(macOS)

import Foundation
import IOKit.hid
import Combine


private let hidPacketLengthInBytes: Int = 64

/**
    CTAP Command bytes
 */
enum CtapCommand: UInt8 {
    case MSG = 0x03
    case INIT = 0x06
    case WINK = 0x08
    case ERROR = 0x3F
    case LOADKEYSEED = 0x62
}


/// This class decodes CTAP HID packets received from a security key
class CtapHidPacketReceived {
    let packet: Data
    
    /// Construct this class to decode the values in a CTAP HID Packet
    /// - Parameter packet: the raw HID packet received
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
    var command: CtapCommand {
        CtapCommand(rawValue: packet[4] & 0x7f) ?? CtapCommand.ERROR
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

/// A class used to decode the contents of an HID INIT response
class CtapHidInitResponseMessage {
    let message: Data
    
    /// Decode an HID INIT response message from the data within the response
    /// - Parameter message: The data encoded in the packet
    init(_ message: Data) {
        self.message = message
    }
    
    // DATA    8-byte nonce
    var nonce: Data {
        Data(message.prefix(8))
    }

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

/// Possible errors returned when sending a CTAP HID Request
enum CtapRequestError: Error {
    case couldNotOpenDevice
    case invalidSeedLength
    case couldNotGenerateRandomNonce
    case errorReturned(Data)
}


/// A connection to an HID device
class CtapHidConnection {
    let device: AttachedHidDevice
    static let maxReportSize: Int = 64
    let report = UnsafeMutablePointer<UInt8>.allocate(capacity: CtapHidConnection.maxReportSize)
    var callbacksForCreateChannelIndexByNonce: [Data: (Result<UInt32, CtapRequestError>) -> Void] = [:]
    var callbacksForLoadKeySeedIndexByChannel: [UInt32: (Result<Void,CtapRequestError>) -> Void] = [:]
    
    
    /// Construct a connection to an HID device
    /// - Parameter device: The device to connect to
    init(_ device: AttachedHidDevice) {
        self.device = device
        
        let this = Unmanaged.passRetained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device.unmanagedDeviceRef, report, CtapHidConnection.maxReportSize, receiveHidMessageWrapper, this)
        
        guard IOHIDDeviceOpen(device.unmanagedDeviceRef, IOOptionBits(kIOHIDOptionsTypeSeizeDevice)) == kIOReturnSuccess else {
            print("Couldn't open HID device")
            return
        }
    }
    
    /// Handle a received HID message packet
    /// - Parameter packet: The received HID packet to interpret as a CTAP HID packet
    private func onReceiveHidMessage(_ packet: CtapHidPacketReceived) {
        print("Read from channel \(String(format:"%02X", packet.channel)) with command \(packet.command) and message \([UInt8](packet.message))")
        if (packet.command == CtapCommand.ERROR) {
            if let callback = callbacksForLoadKeySeedIndexByChannel[packet.channel] {
                callbacksForLoadKeySeedIndexByChannel.removeValue(forKey: packet.channel)
                callback(Result.failure(.errorReturned(packet.message)))
            }
        } else if (packet.isInitializationPacket && packet.command == CtapCommand.INIT) {
            let initResponse = CtapHidInitResponseMessage(packet.message)
            if let callback = callbacksForCreateChannelIndexByNonce[initResponse.nonce] {
                callbacksForCreateChannelIndexByNonce.removeValue(forKey: initResponse.nonce)
                callback(.success(initResponse.channelCreated))
            }
        } else if (packet.isInitializationPacket && packet.command == CtapCommand.LOADKEYSEED) {
            if let callback = callbacksForLoadKeySeedIndexByChannel[packet.channel] {
                callbacksForLoadKeySeedIndexByChannel.removeValue(forKey: packet.channel)
                callback(Result.success(()))
            }
        }
    }
    
    private func receiveHidMessage(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        onReceiveHidMessage(CtapHidPacketReceived(Data(bytes: report, count: reportLength)))
    }
    private let receiveHidMessageWrapper : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
        let this: CtapHidConnection = Unmanaged<CtapHidConnection>.fromOpaque(inContext!).takeUnretainedValue()
        this.receiveHidMessage(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
    }
    
    func sendHidMessage(_ data: Data) -> IOReturn {
        if (data.count > CtapHidConnection.maxReportSize) {
            print("output data too large for USB report")
            return IOReturn(0)
        }
        let reportId : CFIndex = CFIndex(data[0])
        print("Sending output: \([UInt8](data))")
        return IOHIDDeviceSetReport(device.unmanagedDeviceRef, kIOHIDReportTypeOutput, reportId, [UInt8](data), data.count)
    }
    
    func createChannel(callback: @escaping (Result<UInt32, CtapRequestError>) -> Void) {
        var channelCreationNonce = Data(count: 8)
        let result = channelCreationNonce.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 8, $0)
        }
        if result != errSecSuccess {
            callback(.failure(CtapRequestError.couldNotGenerateRandomNonce))
        }
        callbacksForCreateChannelIndexByNonce[channelCreationNonce] = callback
        sendCtapHidMessage(channel: 0xffffffff, command: CtapCommand.INIT.rawValue, data: channelCreationNonce)
        
        print("Sent channel request with nonce \([UInt8](channelCreationNonce))")
    }

    private func sendLoadKeySeed(
        channel: UInt32,
        keySeedAs32Bytes: Data,
        extState: Data = Data(),
        commandVersion: UInt8 = 1,
        callback: @escaping (Result<Void, CtapRequestError>) -> Void
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
        let sendResult = sendCtapHidMessage(channel: channel, command: CtapCommand.LOADKEYSEED.rawValue, data: message)
    }
        
    /// Write a cryptographic seed into a security key for use in deterministically
    /// generating/replacing WebAuthN keys
    /// https://github.com/dicekeys/seeding-webauthn
    ///
    /// - Parameters:
    ///   - keySeedAs32Bytes: A 32-byte seed
    ///   - extState: A short array of bytes (or empty) to store with the seed that might help one to-generate or locate the original seed (default empty)
    ///   - commandVersion: The version of the seeding operation (default 1)
    ///   - callback: A callback for the result/error
    func loadKeySeed(
        keySeedAs32Bytes: Data,
        extState: Data = Data(),
        commandVersion: UInt8 = 1,
        callback: @escaping (Result<Void, CtapRequestError>) -> Void
    ) {
        createChannel(callback: { (result: Result<UInt32, CtapRequestError>) in
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

#endif
