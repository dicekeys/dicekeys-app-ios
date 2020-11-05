//
//  SessionManager.swift
//  DiceKeys
//
//  Created by Nikita Titov on 27.10.2020.
//

import AVFoundation
import ImageIO
import UIKit

let kImageCapturedSuccessfully = "kImageCapturedSuccessfully"

class SessionManger: NSObject {
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCaptureStillImageOutput!
    var stillImage: UIImage!

    var frontCamera: AVCaptureDevice!
    var backCamera: AVCaptureDevice!

    var frontFacingCameraDeviceInput: AVCaptureDeviceInput!
    var backFacingCameraDeviceInput: AVCaptureDeviceInput!

    deinit {
        captureSession.stopRunning()
    }

    init(view: UIView) {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        // Add video input
        do {
            frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)

            // Zoom
            do {
                do {
                    try frontCamera.lockForConfiguration()
                    frontCamera.videoZoomFactor = 1.0
                    frontCamera.unlockForConfiguration()
                } catch {
                    print("Unexpected error: \(error).")
                }

                do {
                    try backCamera.lockForConfiguration()
                    backCamera.videoZoomFactor = 1.0
                    backCamera.unlockForConfiguration()
                } catch {
                    print("Unexpected error: \(error).")
                }
            }

            do {
                frontFacingCameraDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
                backFacingCameraDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            } catch {
                print("Unexpected error: \(error).")
            }
        }

        // Add still Image Output
        do {
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]

            var videoConnection: AVCaptureConnection?

            stillImageOutput.connections.forEach { connection in
                connection.inputPorts.forEach { port in
                    if port.mediaType == .video {
                        videoConnection = connection
                        return
                    }
                }
                if videoConnection != nil {
                    return
                }
            }

            captureSession.addOutput(stillImageOutput)
        }

        // Add video Preview Layer
        do {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill

            previewLayer.bounds = view.layer.bounds
            previewLayer.position = CGPoint(x: view.layer.bounds.midX, y: view.layer.bounds.midY)

            view.layer.addSublayer(previewLayer)
        }
    }

    var backOn: Bool = false {
        didSet {
            willChangeValue(forKey: "flashAvailable")
            if backOn {
                captureSession.beginConfiguration()
                if let currentInput = captureSession.inputs.first {
                    captureSession.removeInput(currentInput)
                }

                if captureSession.canAddInput(backFacingCameraDeviceInput) {
                    captureSession.addInput(backFacingCameraDeviceInput)
                }
//                else {
//                    self.captureSession.addInput(currentInput)
//                }
                captureSession.commitConfiguration()
            } else {
                captureSession.beginConfiguration()
                if let currentInput = captureSession.inputs.first {
                    captureSession.removeInput(currentInput)
                }

                if captureSession.canAddInput(frontFacingCameraDeviceInput) {
                    captureSession.addInput(frontFacingCameraDeviceInput)
                }
//                else {
//                    self.captureSession.addInput(currentInput)
//                }
                captureSession.commitConfiguration()
            }
            didChangeValue(forKey: "flashAvailable")
        }
    }

    var flashAvailable: Bool {
        assert(backCamera != nil)
        if backOn {
            return backCamera.isTorchModeSupported(.on)
        } else {
            return frontCamera.isTorchModeSupported(.on)
        }
    }

    var flashOn: Bool = false {
        didSet {
            if !backOn {
                return
            }
            let mode: AVCaptureDevice.TorchMode = flashOn ? .on : .off
            let modeSupported = backCamera.isTorchModeSupported(mode)
            if !modeSupported {
                return
            }
            captureSession.beginConfiguration()
            do {
                try backCamera.lockForConfiguration()
                backCamera.torchMode = mode
                backCamera.unlockForConfiguration()
                captureSession.commitConfiguration()
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }

    func turnOffFlash() {
        let modeSupported = backCamera.isTorchModeSupported(.off)
        if !modeSupported {
            return
        }

        captureSession.beginConfiguration()
        do {
            try backCamera.lockForConfiguration()

            backCamera.torchMode = .off

            backCamera.unlockForConfiguration()
            captureSession.commitConfiguration()

            willChangeValue(forKey: "flashOn")
            flashOn = false
            didChangeValue(forKey: "flashOn")
        } catch {
            print("Unexpected error: \(error).")
        }
    }

    func captureImage(completion: @escaping ((UIImage?) -> Void)) {
        var videoConnection: AVCaptureConnection?
        stillImageOutput.connections.forEach { connection in
            connection.inputPorts.forEach { port in
                if port.mediaType == .video {
                    videoConnection = connection
                    return
                }
            }
            if videoConnection != nil {
                return
            }
        }

        if videoConnection == nil {
            return
        }

        stillImageOutput.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { buffer, _ -> Void in
            guard let buffer = buffer else {
                return
            }
            if let exifAttachments = CMGetAttachment(buffer, key: kCGImagePropertyExifDictionary, attachmentModeOut: nil) {
                let image = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer).flatMap { UIImage(data: $0) }
                completion(image)
            }
        })
    }
}
