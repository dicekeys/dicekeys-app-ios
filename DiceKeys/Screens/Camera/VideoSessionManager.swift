//
//  VideoSessionManager.swift
//  DiceKeys
//
//  Created by Nikita Titov on 29.10.2020.
//

import AVFoundation
import CoreImage
import CoreMedia
import UIKit

class VideoSessionManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    let cameraPosition: AVCaptureDevice.Position

    var block: ((CIImage) -> Void)?

    required init(cameraPosition: AVCaptureDevice.Position) {
        self.cameraPosition = cameraPosition
        super.init()
        do {
            captureSession.sessionPreset = AVCaptureSession.Preset.photo

            guard let camera = (AVCaptureDevice.devices(for: .video) as! [AVCaptureDevice]).filter({ $0.position == cameraPosition }).first
            else {
                fatalError("Unable to access camera")
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                captureSession.addInput(input)
            } catch {
                fatalError("Unable to access back camera")
            }

            let videoOutput = AVCaptureVideoDataOutput()

            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "SampleBuffer", attributes: []))

            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }

            captureSession.startRunning()
        }
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIWindow.orientation.rawValue)!

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            self.block?(ciImage)
        }
    }
}
