//
//  SwiftUICameraView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/19.
//  Using code from https://github.com/RosayGaspard/SwiftUI-Simple-camera-app/blob/master/SwiftUI-CameraApp/CameraController.swift
//

import SwiftUI
import UIKit
import AVFoundation
import ReadDiceKey

typealias CaptureFrameHandler = (_ imageBitmap: Data, _ width: Int32, _ height: Int32) throws -> Void

final class DiceKeysCameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let videoDispatchQueue = DispatchQueue(label: "diceKeysVideo")

    var captureSession: AVCaptureSession?
    var backCamera: AVCaptureDevice?
    var backCameraInput: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    var onFrameCaptured: CaptureFrameHandler?
    private var _size: CGSize?
    var size: CGSize {
        get { _size ?? UIScreen.main.bounds.size }
        set { _size = newValue }
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

    // Runs in the "SampleBuffer" queue
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if self.onFrameCaptured == nil || self.isProcessingFrame {
            return
        }

        self.isProcessingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            self.isProcessingFrame = false
            return
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            self.isProcessingFrame = false
            return
        }

        guard let bitmap = cgImage.bitmap else {
            self.isProcessingFrame = false
            return
        }
        let width = Int32(cgImage.width)
        let height = Int32(cgImage.height)
        // Stuart asks if this should be here
        // connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIWindow.orientation.rawValue)!

        DiceKeysCameraController.videoDispatchQueue.async {
            defer {
                self.isProcessingFrame = false
            }
            try? self.onFrameCaptured?(bitmap, width, height)
        }
    }

    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
        }
        func configureCaptureDevices() throws {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                throw CameraControllerError.noCamerasAvailable
            }

            self.backCamera = camera

            do {
                // NOTE - for future MacOS compat, follow this:
                // https://developer.apple.com/documentation/avfoundation/avcapturedevice/1387810-lockforconfiguration
                try camera.lockForConfiguration()
                defer {
                    camera.unlockForConfiguration()
                }
                // Nikita used this, which locks focus after initially locking onto center image
                // Stuart believes continuousAutoFocus is necessary to prevent locking into wrong distance
                // device.focusMode = .autoFocus
                if camera.isFocusModeSupported(.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                }
                if camera.isFocusPointOfInterestSupported {
                    // Focus on center
                    camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                }

                if camera.isAutoFocusRangeRestrictionSupported {
                    // Focus close by
                    camera.autoFocusRangeRestriction = .near
                }
                if camera.isExposureModeSupported(.autoExpose) {
                    camera.exposureMode = .autoExpose
                }
            }
        }

        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else {
                throw CameraControllerError.captureSessionIsMissing
            }

            guard let backCamera = self.backCamera else {
                throw CameraControllerError.noCamerasAvailable
            }

            guard let backCameraInput = try? AVCaptureDeviceInput(device: backCamera) else {
                throw CameraControllerError.inputsAreInvalid
            }
            if captureSession.canAddInput(backCameraInput) {
                captureSession.addInput(backCameraInput)
                self.backCameraInput = backCameraInput

                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "SampleBuffer", attributes: []))
                if captureSession.canAddOutput(videoOutput) {
                    captureSession.addOutput(videoOutput)
                }

                captureSession.startRunning()
            }
        }

        DiceKeysCameraController.videoDispatchQueue.async {
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

    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }

        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait

        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
}

final class DiceKeysCameraUIViewController: UIViewController {
    let cameraController = DiceKeysCameraController()

    var previewView: UIView!

    var onFrameCaptured: CaptureFrameHandler? {
        get { return self.cameraController.onFrameCaptured }
        set { DiceKeysCameraController.videoDispatchQueue.async {
                self.cameraController.onFrameCaptured = newValue
            }
        }
    }

    var size: CGSize {
        get { cameraController.size }
        set { cameraController.size = newValue }
    }

    func withOnFrameCaptured(onFrameCaptured newValue: CaptureFrameHandler?) -> DiceKeysCameraUIViewController {
        cameraController.onFrameCaptured = newValue
        return self
    }

    override func viewDidLoad() {
        previewView = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        previewView.contentMode = UIView.ContentMode.scaleAspectFill
        view.addSubview(previewView)

        cameraController.prepare { error in
            if let error = error {
                print(error)
            }

            try? self.cameraController.displayPreview(on: self.previewView)
        }
    }
}

final class DiceKeysCamera: UIViewControllerRepresentable {
    let size: CGSize
    let onFrameProcessed: (() -> Void)?
    let onRead: ((DiceKey) -> Void)?

    private var onReadSentYet = false
    private let processor = DKImageProcessor.create()!

    init(onFrameProcessed: (() -> Void)? = nil, onRead: ((DiceKey) -> Void)? = nil, size: CGSize = UIScreen.main.bounds.size) {
        self.onFrameProcessed = onFrameProcessed
        self.onRead = onRead
        self.size = size
    }

    public typealias UIViewControllerType = DiceKeysCameraUIViewController

    func onFrameCaptured(_ imageBitmap: Data, _ width: Int32, _ height: Int32) throws {
        processor.process(imageBitmap, width: width, height: height)
        let json = processor.json()
        if let facesRead = FaceRead.fromJson(json) {
            // Render overlay image
            if let diceKey = try? DiceKey(facesRead) {
                if !self.onReadSentYet {
                    self.onReadSentYet = true
                    self.onRead?(diceKey)
                }
                // FIXME -- clean up better!
            } else {
            }
        } else {
            // clean overlay image
        }
        processor.overlay(imageBitmap, width: width, height: height)

        DispatchQueue.main.async {
            self.onFrameProcessed?()
        }
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<DiceKeysCamera>) -> DiceKeysCameraUIViewController {
        let controller = DiceKeysCameraUIViewController()
        controller.onFrameCaptured = onFrameCaptured
        controller.size = size
        return controller
    }

    public func updateUIViewController(_ uiViewController: DiceKeysCameraUIViewController, context: UIViewControllerRepresentableContext<DiceKeysCamera>) {
    }
}

struct DiceKeysCameraView: View {
//    let onFrameCaptured: CaptureFrameHandler? = nil

    @State var frameCount: Int = 0

    func onFrameProcessed() {
        self.frameCount += 1
    }

    var body: some View {
        Text("We've processed \(frameCount) frames")
        GeometryReader { reader in
            VStack {
                DiceKeysCamera(onFrameProcessed: onFrameProcessed, size: CGSize(width: min(reader.size.width, reader.size.height), height: min(reader.size.width, reader.size.height)) )
//                UIImage(cgImage: overlayCgImage)
                //.setDimensions(width: reader.size.width, height: reader.size.height)
            }
        }
    }
}

struct TestView: View {
    var body: some View {
        VStack {
            Text("Test View")
            Spacer()
            DiceKeysCameraView()
        }
    }
}

@main
struct DiceKeysCameraApp: App {
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}

struct DiceKeysCameraView_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeysCameraView()
    }
}
