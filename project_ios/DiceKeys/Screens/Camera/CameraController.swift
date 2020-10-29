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
    var viewModel: CameraViewModel!
    var captureManager: SessionManger!
    var isCapturing: Bool!
    var image: UIImage? {
        didSet {
            viewModel.image = image
            viewModel.imageData = image?.jpegData(compressionQuality: 0.51)
            if image != nil {
                prepareForImageAccept()
            }
        }
    }

    @IBOutlet var buttonFlash: UIBarButtonItem!

    @IBOutlet var sessionContainer: UIView!

    @IBOutlet var buttonFlip: UIButton!
    @IBOutlet var buttonGallery: UIButton!
    @IBOutlet var buttonTake: UIButton!

    @IBOutlet var imageView: UIImageView!

    @IBOutlet var buttonRetake: UIButton!
    var buttonContinue: UIBarButtonItem!

    @IBOutlet var mainContainer: CaptureView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create continue button
        do {
            buttonContinue = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(actionContinue))
            buttonContinue.accessibilityLabel = "Next"
        }

        viewModel = CameraViewModel()
        assert(viewModel != nil)

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
            captureManager = SessionManger(view: sessionContainer)
            captureManager.backOn = false

            NotificationCenter.default.addObserver(self, selector: #selector(imageCapturedSuccessfully), name: NSNotification.Name(kImageCapturedSuccessfully), object: nil)

            DispatchQueue.global().async {
                self.captureManager.captureSession.startRunning()
            }

            // TODO: Manage flash button state
            // RAC(self.buttonFlash, enabled) = RACSignal combineLatest:@[
            //     RACObserve(self.captureManager, flashAvailable),
            //     RACObserve(self, isCapturing),
            // ]
            // reduce:^id(NSNumber *flashAvailable, NSNumber *isCapturing){
            //     BOOL enabled = flashAvailable.boolValue && isCapturing.boolValue
            //     return @(enabled)
            // }

        #endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureManager.flashOn = false
    }

    // MARK: - Capture/Accept State

    func prepareForImageCapture() {
        buttonFlip.isHidden = false
        navigationItem.rightBarButtonItem = buttonFlash
        buttonGallery.isHidden = false
        buttonTake.isHidden = false

        imageView.image = nil
        imageView.isHidden = true
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

        actionDisableFlash()

        isCapturing = false
    }

    // MARK: -

    @objc func imageCapturedSuccessfully() {
        let orig = captureManager.stillImage!

        //        UIImageWriteToSavedPhotosAlbum(orig, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)

        // Test
        do {
            // Initialize wrapper
            let wrapper = DKImageProcessor.create()!

            // Load test image from bundle
            let image = orig

            let w = Int32(image.bitmapWidth)
            let h = Int32(image.bitmapHeight)

            let data = image.rgba()

            // Test API
            // processRGBAImageAndRenderOverlay
//            var overlay = wrapper.processRGBAImageAndRenderOverlay(w, height: h, bytes: data)
//            overlay.withUnsafeMutableBytes { rawBufferPointer in
//                let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
//                let overlayImage = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)
//
//                imageView.image = overlayImage
//            }

            var augmented = wrapper.processAndAugmentRGBAImage(w, height: h, bytes: data)
            augmented.withUnsafeMutableBytes { rawBufferPointer in
                let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                let image = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)

                self.image = image
            }
        }

        captureManager.previewLayer.connection!.isEnabled = true
        enableButtons()
    }

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

    @IBAction func actionToggleFlash() {
        if captureManager.flashOn {
            actionDisableFlash()
        } else {
            actionEnableFlash()
        }
    }

    func actionEnableFlash() {
        captureManager.flashOn = true
        buttonFlash.image = UIImage(systemName: "bolt")
    }

    func actionDisableFlash() {
        captureManager.flashOn = false
        buttonFlash.image = UIImage(systemName: "bolt.slash")
    }

    @IBAction func actionFlipCamera() {
        if captureManager.backOn {
            captureManager.backOn = false
            captureManager.turnOffFlash()
        } else {
            captureManager.backOn = true
        }
    }

    @IBAction func actionGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    @IBAction func actionTakeImage() {
        captureManager.captureStillImage()
        captureManager.previewLayer.connection!.isEnabled = false
        disableButtons()
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
