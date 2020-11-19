//
//  CaptureView.swift
//  DiceKeys
//
//  Created by Nikita Titov on 27.10.2020.
//

import AVFoundation
import UIKit

class FocusSquare: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        layer.borderWidth = 0.5
        layer.cornerRadius = 2
        layer.borderColor = UIColor.white.cgColor

        let selectionAnimation = CABasicAnimation(keyPath: "borderColor")
        selectionAnimation.toValue = UIColor.gray.cgColor
        selectionAnimation.repeatCount = 2
        layer.add(selectionAnimation, forKey: "selectionAnimation")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

class CaptureView: UIView {
    weak var controller: CameraController!
    var focusSquare: FocusSquare?

    override func touchesBegan(_: Set<UITouch>, with event: UIEvent?) {
        guard let touch = event?.allTouches?.first else {
            return
        }
        let touchPoint = touch.location(in: touch.view)
        focus(on: touchPoint)

        if let focusSquare = self.focusSquare {
            focusSquare.removeFromSuperview()
        }

        let width: CGFloat = 80
        focusSquare = FocusSquare(frame: CGRect(x: touchPoint.x - width / 2, y: touchPoint.y - width / 2, width: width, height: width))
        addSubview(focusSquare!)
        focusSquare!.setNeedsDisplay()

        UIView.animate(withDuration: 1.0) {
            self.focusSquare?.alpha = 0
        }
    }

    func focus(on aPoint: CGPoint) {
        #if targetEnvironment(simulator)

        #else

            guard let device = AVCaptureDevice.default(for: .video) else {
                return
            }
            if !(device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus)) {
                return
            }

            let screenRect = UIScreen.main.bounds
            let screenWidth = screenRect.size.width
            let screenHeight = screenRect.size.height
            let focus_x = aPoint.x / screenWidth
            let focus_y = aPoint.y / screenHeight

            do {
                // NOTE - for future MacOS compat, follow this:
                // https://developer.apple.com/documentation/avfoundation/avcapturedevice/1387810-lockforconfiguration
                try device.lockForConfiguration()
                defer {
                    device.unlockForConfiguration()
                }
                // Nikita used this, which locks focus after initially locking onto center image
                // Stuart believes continuousAutoFocus is necessary to prevent locking into wrong distance
                // device.focusMode = .autoFocus
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
                }

                if device.isAutoFocusRangeRestrictionSupported {
                    device.autoFocusRangeRestriction = .near
                }
                // Stuart wonders if this might allow us to focus close by default
                // https://developer.apple.com/documentation/avfoundation/avcapturedevice/1389191-focusmode
                // device.focusMode = AVCaptureDevice.FocusMode(0)

                if device.isExposureModeSupported(.autoExpose) {
                    device.exposureMode = .autoExpose
                }
            } catch {
                print("Unexpected error: \(error).")
            }

        #endif
    }
}
