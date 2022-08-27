//
//  String.swift
//  DiceKeys (iOS)
//
//  Created by Angelos Veglektsis on 7/20/22.
//

import Foundation
import UIKit
import CoreImage.CIFilterBuiltins

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}

extension Optional where Wrapped == String {
  var isBlank: Bool {
    return self?.isBlank ?? true
  }
}

extension String {
  func trim() -> String {
      return self.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

extension String {
    func toQRCode() -> UIImage {

        let context = CIContext()
        let ciFilter = CIFilter.qrCodeGenerator()
        
        ciFilter.message = Data(self.utf8)

        if let outputImage = ciFilter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
