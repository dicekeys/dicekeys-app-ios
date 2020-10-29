//
//  UIImage+RGBA.swift
//  DiceKeys
//
//  Created by Nikita Titov on 29.10.2020.
//

import UIKit

extension UIImage {
    var bitmapWidth: Int {
        cgImage?.width ?? 0
    }

    var bitmapHeight: Int {
        cgImage?.height ?? 0
    }

    func rgba() -> Data? {
        /*
         Maybe whole rgba code could be replaced as

         func rgba() -> Data? {
         self.cgImage?.dataProvider?.data as? Data
         }
         */
        // Return empty `Data` collection if `UIImage` itself is empty
        //        guard let bitmap = self.cgImage?.dataProvider?.data else {
        //            return Data()
        //        }
        //
        //        var bytes = [UInt8]()
        //        var ptr: UnsafePointer<UInt8> = CFDataGetBytePtr(bitmap)
        //
        //        for _ in 0 ..< Int(self.size.height) {
        //            for _ in 0 ..< Int(self.size.width) {
        //                // Read r, g, b, a bytes from binary string
        //                let r = ptr.pointee; ptr = ptr.advanced(by: 1)
        //                let g = ptr.pointee; ptr = ptr.advanced(by: 1)
        //                let b = ptr.pointee; ptr = ptr.advanced(by: 1)
        //                let a = ptr.pointee; ptr = ptr.advanced(by: 1)
        //                // Save values to array
        //                bytes.append(r)
        //                bytes.append(g)
        //                bytes.append(b)
        //                bytes.append(a)
        //            }
        //        }
        //
        //        return Data(bytes)
        cgImage?.dataProvider?.data as? Data
    }
}

public extension CGFloat {
    func toRadians() -> CGFloat {
        self / (180 * .pi)
    }

    func toDegrees() -> CGFloat {
        self * (180 * .pi)
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}
