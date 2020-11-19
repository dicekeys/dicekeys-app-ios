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


//class VideoSessionManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
//    let captureSession: AVCaptureSession
//    let cameraPosition: AVCaptureDevice.Position
//
//    var block: ((CIImage) -> Void)?
//
//    required init(captureSession: AVCaptureSession) {
//        super.init()
//        do {
//            self.captureSession = captureSession
//
//            let videoOutput = AVCaptureVideoDataOutput()
//            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "SampleBuffer", attributes: []))
//            if captureSession.canAddOutput(videoOutput) {
//                captureSession.addOutput(videoOutput)
//            }
//            captureSession.startRunning()
//        }
//    }
//
//    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
//
//}

final class DiceKeysCameraController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var backCamera: AVCaptureDevice?
    var backCameraInput: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?

    enum CameraControllerError: Swift.Error {
       case captureSessionAlreadyRunning
       case captureSessionIsMissing
       case inputsAreInvalid
       case invalidOperation
       case noCamerasAvailable
       case unknown
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIWindow.orientation.rawValue)!

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            // FIXME
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

        DispatchQueue(label: "prepare").async {
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

final class CameraViewController: UIViewController {
//    var widthSet: CGFloat?
//    var heightSet: CGFloat?
//
//    func setDimensions (width: CGFloat, height: CGFloat) -> CameraViewController {
//        self.widthSet = width
//        self.heightSet = height
//        return self
//    }
//
//    var width: CGFloat {
//        widthSet ?? UIScreen.main.bounds.size.width
//    }
//    var height: CGFloat {
//        heightSet ?? UIScreen.main.bounds.size.height
//    }

    let cameraController = DiceKeysCameraController()
    var previewView: UIView!

    override func viewDidLoad() {
//        previewView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let screenSize = UIScreen.main.bounds.size
        let minSize = min(screenSize.width, screenSize.height)
        previewView = UIView(frame: CGRect(x: 0, y: 0, width: minSize, height: minSize))
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

extension CameraViewController: UIViewControllerRepresentable {
    public typealias UIViewControllerType = CameraViewController

    public func makeUIViewController(context: UIViewControllerRepresentableContext<CameraViewController>) -> CameraViewController {
        return CameraViewController()
    }

    public func updateUIViewController(_ uiViewController: CameraViewController, context: UIViewControllerRepresentableContext<CameraViewController>) {
    }
}

struct SwiftUiCameraView: View {
    var body: some View {
//        GeometryReader { reader in
        VStack {
            Text("Hi, we're here")
            CameraViewController()//.setDimensions(width: reader.size.width, height: reader.size.height)
        }
//        }
    }
}

@main
struct SwiftUICameraApp: App {
    var body: some Scene {
        WindowGroup {
            SwiftUiCameraView()
        }
    }
}

struct SwiftUICameraView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUiCameraView()
    }
}
