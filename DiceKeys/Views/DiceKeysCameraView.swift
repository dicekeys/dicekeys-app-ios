//
//  SwiftUICameraView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/19.
//

import SwiftUI
import UIKit
import AVFoundation
import ReadDiceKey

final class DiceKeysCameraUIViewController: UIViewController {
    let cameraController = DiceKeysCameraController()

    var previewView: UIView!

    var onFrameCaptured: CaptureFrameHandler? {
        get { return self.cameraController.onFrameCaptured }
        set { DiceKeysCameraController.processedFrameDispatchQueue.async {
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

    override func viewWillDisappear(_ animated: Bool) {
        cameraController.stop()
        print("Camera stopped")
    }
}

final class DiceKeysCamera: UIViewControllerRepresentable {
    let size: CGSize
    let onFrameProcessed: ((_ processedImageFrameSize: CGSize, _ facesRead: [FaceRead]?) -> Void)?
    let onRead: ((DiceKey) -> Void)?

    private var onReadSentYet = false
    private let processor = DKImageProcessor.create()!

    init(onFrameProcessed: ((_ processedImageFrameSize: CGSize, _ facesRead: [FaceRead]?) -> Void)? = nil, onRead: ((DiceKey) -> Void)? = nil, size: CGSize = UIScreen.main.bounds.size) {
        self.onFrameProcessed = onFrameProcessed
        self.onRead = onRead
        self.size = size
    }

    public typealias UIViewControllerType = DiceKeysCameraUIViewController

    func onFrameCaptured(_ imageBitmap: Data, _ width: Int32, _ height: Int32) {
        processor.process(imageBitmap, width: width, height: height)
        let json = processor.json()
        let facesReadOrNil = FaceRead.fromJson(json)
        if let facesRead = facesReadOrNil {
            // Render overlay image
            if let diceKey = try? DiceKey(facesRead) {
                if !self.onReadSentYet {
                    self.onReadSentYet = true
                    self.onRead?(diceKey)
                }
            }
        }
        self.onFrameProcessed?(CGSize(width: CGFloat(width), height: CGFloat(height)), facesReadOrNil)
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<DiceKeysCamera>) -> DiceKeysCameraUIViewController {
        let controller = DiceKeysCameraUIViewController()
        controller.onFrameCaptured = onFrameCaptured
        controller.size = size
        return controller
    }

    public func updateUIViewController(_ uiViewController: DiceKeysCameraUIViewController, context: UIViewControllerRepresentableContext<DiceKeysCamera>) {
    }

//    static func dismantleUIViewController(_ uiViewController: DiceKeysCameraUIViewController, coordinator: ()) {
//    }
}

struct DiceKeysCameraView: View {
    let onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)?

    init(onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)? = nil) {
        self.onDiceKeyRead = onDiceKeyRead
    }

    @State var frameCount: Int = 0
    @State var facesRead: [FaceRead]?
    @State var processedImageFrameSize: CGSize?

    func onFrameProcessed(_ processedImageFrameSize: CGSize, _ facesRead: [FaceRead]?) {
        self.frameCount += 1
        self.processedImageFrameSize = processedImageFrameSize
        self.facesRead = facesRead
        if facesRead?.count == 25 && facesRead?.allSatisfy({ faceRead in faceRead.errors.count == 0 }) == true {
            try? onDiceKeyRead?(DiceKey(facesRead!).rotatedClockwise90Degrees())
        }
    }

    var body: some View {
        VStack {
            Text("\(frameCount) frames processed")
            GeometryReader { reader in
                ZStack {
                    DiceKeysCamera(onFrameProcessed: onFrameProcessed, size: CGSize(width: min(reader.size.width, reader.size.height), height: min(reader.size.width, reader.size.height)) )

                    FacesReadOverlay(
                        renderedSize: CGSize(width: min(reader.size.width, reader.size.height), height: min(reader.size.width, reader.size.height)),
                        imageFrameSize: processedImageFrameSize ?? CGSize(width: min(reader.size.width, reader.size.height), height: min(reader.size.width, reader.size.height)),
                        facesRead: self.facesRead
                    )
                }
            }
        }
    }
}

struct DiceKeysCameraView_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeysCameraView()
    }
}
