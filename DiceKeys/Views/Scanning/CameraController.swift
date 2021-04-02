//
//  CameraController.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/23.
//  Using code from https://github.com/RosayGaspard/SwiftUI-Simple-camera-app/blob/master/SwiftUI-CameraApp/CameraController.swift
//

import Foundation
import AVFoundation

#if os(iOS)
import UIKit
#else
import AppKit
#endif

typealias CaptureFrameHandler = (_ imageBitmap: Data, _ width: Int32, _ height: Int32) throws -> Void

final class DiceKeysCameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let processedFrameDispatchQueue = DispatchQueue(label: "diceKeysVideo")

    var captureSession: AVCaptureSession?
    var camera: AVCaptureDevice?
    var cameraInput: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    #if os(iOS)
    let defaultSize = UIScreen.main.bounds.size
    #else
    let defaultSize = CGSize(width: 300, height: 300)
    #endif

    var onFrameCaptured: CaptureFrameHandler?
    private var _size: CGSize?
    var size: CGSize {
        get { _size ?? defaultSize }
        set { _size = newValue }
    }

    func stop() {
        captureSession?.stopRunning()
    }

    enum CameraControllerError: Swift.Error {
       case captureSessionAlreadyRunning
       case captureSessionIsMissing
       case inputsAreInvalid
       case invalidOperation
       case noCamerasAvailable
       case unknown
    }

    private var isProcessingFrame: Bool = false
    private var reusableFrameDataBuffer = Data()

    // Runs in the "quicklyProcessSampleBuffer" queue
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.onFrameCaptured == nil || self.isProcessingFrame {
            return
        }

        self.isProcessingFrame = true

        // Here there be dragons.
        // This is from sample code, but it introduces a 5 second delay
        // (maybe do from being called in the wrong thread?)
        // connection.videoOrientation = AVCaptureVideoOrientation.portrait
        guard let imageBuffer: CVPixelBuffer = sampleBuffer.imageBuffer  else {
            self.isProcessingFrame = false
            return
        }

        #if os(macOS)
        // Frames are captured in portrait mode by default and need to be rotated 90 degrees counterclockwise on Macs
        // where landscape is the default orientation of webcams
        let ciImage = CIImage(cvPixelBuffer: imageBuffer).oriented(.left)
        #else
        // preview layer orientation
        if let previewLayerConnection = previewLayer?.connection {
          let orientation = UIDevice.current.orientation
          if (previewLayerConnection.isVideoOrientationSupported) {
            switch (orientation) {
            case .portrait:
              previewLayerConnection.videoOrientation = .portrait
            case .landscapeRight:
              previewLayerConnection.videoOrientation = .landscapeLeft
            case .landscapeLeft:
              previewLayerConnection.videoOrientation = .landscapeRight
            case .portraitUpsideDown:
              previewLayerConnection.videoOrientation = .portraitUpsideDown
            default: break
            }
          }
        }

        // frame buffer orientation
        var ciImageOrientation = CGImagePropertyOrientation.up
        if let previewLayerOrientation = previewLayer?.connection?.videoOrientation {
          switch previewLayerOrientation {
          case .landscapeLeft:
            ciImageOrientation = CGImagePropertyOrientation.right
          case .landscapeRight:
            ciImageOrientation = CGImagePropertyOrientation.left
          case .portraitUpsideDown:
            ciImageOrientation = CGImagePropertyOrientation.down
          default: break
          }
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer).oriented(ciImageOrientation)
        #endif

        let frameWidth = ciImage.extent.width
        let frameHeight = ciImage.extent.height
        let squareSize = min(frameWidth, frameHeight)
        let width = squareSize
        let height = squareSize
        let centeredSquare = CGRect(
            x: (frameWidth - squareSize) / 2,
            y: (frameHeight - squareSize) / 2,
            width: width, height: height
        )
        guard let cgImage = CIContext.init(options: nil).createCGImage(ciImage, from: centeredSquare) else {
            self.isProcessingFrame = false
            return
        }
        let bytesPerRow = 4 * cgImage.width
        let bufferLength = bytesPerRow * cgImage.height
        if reusableFrameDataBuffer.count < bufferLength {
            // We need a bigger buffer.  Allocate it
            reusableFrameDataBuffer = Data(count: bufferLength)
        }
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        reusableFrameDataBuffer.withUnsafeMutableBytes { rawBuffer in
            CGContext(
                data: rawBuffer.baseAddress,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo.rawValue
            )?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        }
        DiceKeysCameraController.processedFrameDispatchQueue.async {
            defer {
                self.isProcessingFrame = false
            }
            try? self.onFrameCaptured?(self.reusableFrameDataBuffer, Int32(width), Int32(height))
        }
    }

    func prepare(_ selectedCamera: AVCaptureDevice?, completionHandler: @escaping (Error?) -> Void) {
        guard let camera = selectedCamera else { return }
        func createCaptureSession() {
            if let captureSession = self.captureSession, captureSession.isRunning {
                captureSession.stopRunning()
            }
            self.captureSession = AVCaptureSession()
        }
        func configureCaptureDevices() throws {
            
            do {
                // NOTE - for future MacOS compat, follow this:
                // https://developer.apple.com/documentation/avfoundation/avcapturedevice/1387810-lockforconfiguration
                try camera.lockForConfiguration()
                defer {
                    camera.unlockForConfiguration()
                }
                if camera.isFocusModeSupported(.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                }
                if camera.isFocusPointOfInterestSupported {
                    // Focus on center
                    camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                }
                #if os(iOS)
                if camera.isAutoFocusRangeRestrictionSupported {
                    // Focus close by
                    camera.autoFocusRangeRestriction = .near
                }
                #endif
                if camera.isExposureModeSupported(.autoExpose) {
                    camera.exposureMode = .continuousAutoExposure
                }
            }
        }

        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else {
                throw CameraControllerError.captureSessionIsMissing
            }

            guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
                throw CameraControllerError.inputsAreInvalid
            }

            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
                self.cameraInput = cameraInput

                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "quicklyProcessSampleBuffer", attributes: []))
                if captureSession.canAddOutput(videoOutput) {
                    captureSession.addOutput(videoOutput)
                }

                captureSession.startRunning()
            }
        }

        DiceKeysCameraController.processedFrameDispatchQueue.async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }

            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }

    func displayPreview(on view: XXView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        let layer:CALayer? = view.layer
        if let layer = layer {
            layer.insertSublayer(previewLayer, at: 0)
        }
        previewLayer.frame = view.frame

        // Auto-mirroring feature for front camera is not working on macOS
        // because AVCaptureDevice.Position set as `unspecified`
        #if os(macOS)
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        #endif
        self.previewLayer = previewLayer
    }
}
