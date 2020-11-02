//
//  CameraController.swift
//  DiceKeys
//
//  Created by Nikita Titov on 27.10.2020.
//

import AssetsLibrary
import Photos
import QuartzCore
import UIKit

class CameraController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //    var sessionManager: SessionManger!
    var videoSessionManager: VideoSessionManager!
    var isCapturing: Bool!
    var image: UIImage?
    var timer: Timer?

    @IBOutlet var buttonFlash: UIBarButtonItem!

    @IBOutlet var sessionContainer: UIView!

    @IBOutlet var buttonFlip: UIButton!
    @IBOutlet var buttonGallery: UIButton!
    @IBOutlet var buttonTake: UIButton!

    @IBOutlet var imageView: UIImageView!

    @IBOutlet var buttonRetake: UIButton!
    var buttonContinue: UIBarButtonItem!

    @IBOutlet var mainContainer: CaptureView!

    deinit {
        timer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create continue button
        do {
            buttonContinue = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(actionContinue))
            buttonContinue.accessibilityLabel = "Next"
        }

        buttonFlip.imageView!.contentMode = UIView.ContentMode.center
        buttonRetake.imageView!.contentMode = UIView.ContentMode.center

        buttonGallery.imageView!.contentMode = UIView.ContentMode.scaleAspectFill
        buttonGallery.layer.cornerRadius = 8
        buttonGallery.clipsToBounds = true

        mainContainer.controller = self

        prepareForImageCapture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        #if targetEnvironment(simulator)
        image = UIImage(named: "Photo")
        #else
        //            if sessionManager == nil {
        //                sessionManager = SessionManger(view: sessionContainer)
        //                sessionManager.backOn = false
        //
        //                DispatchQueue.global().async {
        //                    self.sessionManager.captureSession.startRunning()
        //                }
        //
        //                // TODO: Manage flash button state
        //                // RAC(self.buttonFlash, enabled) = RACSignal combineLatest:@[
        //                //     RACObserve(self.sessionManager, flashAvailable),
        //                //     RACObserve(self, isCapturing),
        //                // ]
        //                // reduce:^id(NSNumber *flashAvailable, NSNumber *isCapturing){
        //                //     BOOL enabled = flashAvailable.boolValue && isCapturing.boolValue
        //                //     return @(enabled)
        //                // }
        //            }
        // Add video session manager
        do {
            if videoSessionManager == nil {
                // Create session manager
                var skippedFrames = 0
                videoSessionManager = VideoSessionManager(cameraPosition: .back)
                videoSessionManager.block = { ciImage in
                    skippedFrames += 1
                    if skippedFrames < 10 {
                        return
                    }

                    let context = CIContext(options: nil)
                    let cgImage = context.createCGImage(ciImage, from: ciImage.extent)!

                    guard let data = cgImage.bitmap else {
                        return
                    }

                    let processor = DKImageProcessor.create()!

                    let w = cgImage.width
                    let h = cgImage.height

                    // Test API
                    // processRGBAImageAndRenderOverlay
                    //            var overlay = wrapper.processRGBAImageAndRenderOverlay(w, height: h, bytes: data)
                    //            overlay.withUnsafeMutableBytes { rawBufferPointer in
                    //                let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    //                let overlayImage = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)
                    //
                    //                imageView.image = overlayImage
                    //            }

                    let bitmap = processor.processRGBAImageAndRenderOverlay(Int32(w), height: Int32(h), bytes: data)

                    if let image = UIImage(bitmap: bitmap, width: w, height: h) {
                        self.image = image
                        self.imageView.image = self.image
                        self.imageView.isHidden = false
                    }

                    skippedFrames = 0
                }

                // Add video preview layer
                do {
                    let view = self.sessionContainer!

                    let previewLayer = AVCaptureVideoPreviewLayer(session: videoSessionManager.captureSession)
                    previewLayer.videoGravity = .resizeAspectFill

                    previewLayer.bounds = view.layer.bounds
                    previewLayer.position = CGPoint(x: view.layer.bounds.midX, y: view.layer.bounds.midY)

                    view.layer.addSublayer(previewLayer)
                }

                // Set up timer
                if timer == nil {
                    //                    timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
                    //                        self.sessionManager.captureImage { image in
                    //                            if let image = image {
                    //                                let processor = DKImageProcessor.create()!
                    //
                    //                                let w = Int32(image.bitmapWidth)
                    //                                let h = Int32(image.bitmapHeight)
                    //
                    //                                let data = image.rgba()
                    //
                    //                                // Test API
                    //                                // processRGBAImageAndRenderOverlay
                    //                                //            var overlay = wrapper.processRGBAImageAndRenderOverlay(w, height: h, bytes: data)
                    //                                //            overlay.withUnsafeMutableBytes { rawBufferPointer in
                    //                                //                let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    //                                //                let overlayImage = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)
                    //                                //
                    //                                //                imageView.image = overlayImage
                    //                                //            }
                    //
                    //                                var overlay = processor.processRGBAImageAndRenderOverlay(w, height: h, bytes: data)
                    //                                overlay.withUnsafeMutableBytes { rawBufferPointer in
                    //                                    let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    //                                    let image = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)?.rotate(radians: Float.pi / 2)
                    //
                    //                                    self.image = image
                    //                                    self.imageView.image = image
                    //                                }
                    //                            } else {
                    //                                self.imageView.image = nil
                    //                            }
                    //                        }
                    //                    })
                }

            }
        }
        #endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        sessionManager.flashOn = false
    }

    // MARK: - Capture/Accept State

    func prepareForImageCapture() {
        buttonFlip.isHidden = false
        navigationItem.rightBarButtonItem = buttonFlash
        buttonGallery.isHidden = false
        buttonTake.isHidden = false

        //        imageView.image = nil
        //        imageView.isHidden = true
        buttonRetake.isHidden = true

        isCapturing = true

        #if targetEnvironment(simulator)
        buttonTake.isEnabled = false
        #else
        buttonTake.isEnabled = true
        #endif

        updateGalleryButtonImage()
    }

    func prepareForImageAccept() {
        navigationItem.rightBarButtonItem = buttonContinue

        buttonFlip.isHidden = true
        buttonGallery.isHidden = true
        buttonTake.isHidden = true

        imageView.image = image
        imageView.isHidden = false
        buttonRetake.isHidden = false

        //        actionDisableFlash()

        isCapturing = false
    }

    // MARK: -

    @objc func image(_: UIImage, didFinishSavingWithError error: NSError?, contextInfo _: UnsafeRawPointer) {
        if let error = error {
            //            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            //            ac.addAction(UIAlertAction(title: "OK", style: .default))
            //            present(ac, animated: true)
            print("Error: \(error)")
        } else {
            //            let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
            //            ac.addAction(UIAlertAction(title: "OK", style: .default))
            //            present(ac, animated: true)
        }
    }

    func updateGalleryButtonImage() {
        let imgManager = PHImageManager.default()
        let fetchOptions = PHFetchOptions()
        fetchOptions.fetchLimit = 1
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)

        if let last = fetchResult.lastObject {
            let scale = UIScreen.main.scale
            let size = CGSize(width: 100 * scale, height: 100 * scale)
            let options = PHImageRequestOptions()

            imgManager.requestImage(for: last, targetSize: size, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: { image, _ in
                if let image = image {
                    self.buttonGallery.setImage(image, for: .normal)
                    self.buttonGallery.setImage(image, for: .disabled)
                }
            })
        }
    }

    // MARK: - Flash

    //    @IBAction func actionToggleFlash() {
    //        if sessionManager.flashOn {
    //            actionDisableFlash()
    //        } else {
    //            actionEnableFlash()
    //        }
    //    }
    //
    //    func actionEnableFlash() {
    //        sessionManager.flashOn = true
    //        buttonFlash.image = UIImage(systemName: "bolt")
    //    }
    //
    //    func actionDisableFlash() {
    //        sessionManager.flashOn = false
    //        buttonFlash.image = UIImage(systemName: "bolt.slash")
    //    }

    @IBAction func actionFlipCamera() {
        //        if sessionManager.backOn {
        //            sessionManager.backOn = false
        //            sessionManager.turnOffFlash()
        //        } else {
        //            sessionManager.backOn = true
        //        }
    }

    @IBAction func actionGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @IBAction func actionTakeImage() {
        //        sessionManager.captureImage()
        //        sessionManager.previewLayer.connection!.isEnabled = false
        //        disableButtons()
    }

    @IBAction func actionRetake() {
        image = nil
        prepareForImageCapture()
    }

    @IBAction func actionContinue() {
        print("[MYLOG] actionContinue")
    }

    // MARK: - Enable / Disable button

    func disableButtons() {
        buttonTake.isEnabled = false
        buttonGallery.isEnabled = false
        buttonRetake.isEnabled = false
        buttonFlash.isEnabled = false
        buttonFlip.isEnabled = false
        buttonContinue.isEnabled = false
    }

    func enableButtons() {
        buttonTake.isEnabled = true
        buttonGallery.isEnabled = true
        buttonRetake.isEnabled = true
        buttonFlash.isEnabled = true
        buttonFlip.isEnabled = true
        buttonContinue.isEnabled = true
    }

    // MARK: - Image Picker Controller Delegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        prepareForImageAccept()
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
