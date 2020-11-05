//
//  Bitmap.swift
//  DiceKeys
//
//  Created by Nikita Titov on 29.10.2020.
//

import UIKit

public extension UIImage {
    convenience init?(bitmap: Data, width: Int, height: Int) {
        guard let cgImage = CGImage.make(from: bitmap, width: width, height: height) else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    var bitmap: Data? {
        cgImage?.bitmap
    }
}

public extension CGImage {
    var bitmap: Data? {
        let bitsPerComponent = 8
        let bytesPerRow = 4 * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        let bufferLength = width * height * 4
        var buffer = [UInt8](repeating: 0, count: bufferLength)

        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Data(buffer)
    }

    static func make(from bitmap: Data, width: Int, height: Int) -> CGImage? {
        let bitsPerComponent = 8
        let bitsPerPixel = 4 * 8
        let bytesPerRow = 4 * width
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider = CGDataProvider(data: bitmap as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
