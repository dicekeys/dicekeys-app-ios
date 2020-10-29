//
//  UIImage+RGBA.swift
//  DiceKeys
//
//  Created by Nikita Titov on 29.10.2020.
//

import UIKit

extension UIImage {
    var bitmapWidth: Int32 {
        guard let value = self.cgImage?.width else {
            return 0
        }
        return Int32(value)
    }

    var bitmapHeight: Int32 {
        guard let value = self.cgImage?.height else {
            return 0
        }
        return Int32(value)
    }

    func rgba() -> Data {
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
        if let cfData = self.cgImage?.dataProvider?.data {
            return cfData as Data
        } else {
            return Data()
        }
    }
}
