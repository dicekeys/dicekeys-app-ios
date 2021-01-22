//
//  ActiveCameras.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/01/20.
//
import AVFoundation
import Foundation

class ActiveCameras {
    static private var cache: [AVCaptureDevice]?
    static private var lastLoaded: Date?
    
    // Get the list of active cameras, caching the result for 0.1 seconds
    static func get() -> [AVCaptureDevice] {
        if cache == nil || cache?.count == 0 || lastLoaded == nil || (lastLoaded?.timeIntervalSinceNow.magnitude ?? 1) > 0.1 {
            #if os(iOS) 
            cache = AVCaptureDevice.DiscoverySession(
                deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            ).devices.filter { device in device.canBeDisplayed }
            #elseif os(macOS)
            cache = AVCaptureDevice.DiscoverySession(
                deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, .externalUnknown],
                mediaType: .video,
                position: .unspecified
            ).devices.filter { device in device.canBeDisplayed }
            #endif
        }
        return cache!
    }
}
