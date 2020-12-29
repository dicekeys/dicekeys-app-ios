//
//  PlatformTypes.swift
//  DiceKeys
//
//  Created by bakhtiyor on 28/12/20.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit

typealias XXView = UIView
typealias XXViewController = UIViewController
typealias XXViewControllerRepresentableContext = UIViewControllerRepresentableContext
typealias XXGraphicsImageRenderer = UIGraphicsImageRenderer
typealias XXImage = UIImage
typealias XXColor = UIColor
typealias XXFont = UIFont

extension Font {
    func inconsolataBold(size: Float) -> Font {
        let font = UIFont(name: "Inconsolata-Bold", size: CGFloat(90))!
        return Font(font)
    }
}


#else
import Cocoa
import AppKit

typealias XXView = NSView
typealias XXViewController = NSViewController
typealias XXViewControllerRepresentableContext = NSViewControllerRepresentableContext
typealias XXGraphicsImageRenderer = MacGraphicsImageRenderer
typealias XXImage = NSImage
typealias XXColor = NSColor
typealias XXFont = NSFont

extension Font {
    func inconsolataBold(size: CGFloat) -> Font {
        Font.system(size: size)
    }
}

public class MacGraphicsImageRendererFormat: NSObject {
    public var opaque: Bool = false
    public var prefersExtendedRange: Bool = false
    public var scale: CGFloat = 2.0
    public var bounds: CGRect = .zero
}

public class MacGraphicsImageRendererContext: NSObject {
    public var format: MacGraphicsImageRendererFormat
    
    public var cgContext: CGContext {
        guard let context = NSGraphicsContext.current?.cgContext
            else { fatalError("Unavailable cgContext while drawing") }
        return context
    }
    
    public func clip(to rect: CGRect) {
        cgContext.clip(to: rect)
    }
    
    public func fill(_ rect: CGRect) {
        cgContext.fill(rect)
    }
    
    public func fill(_ rect: CGRect, blendMode: CGBlendMode) {
        NSGraphicsContext.saveGraphicsState()
        cgContext.setBlendMode(blendMode)
        cgContext.fill(rect)
        NSGraphicsContext.restoreGraphicsState()
    }
    
    public func stroke(_ rect: CGRect) {
        cgContext.stroke(rect)
    }
    
    public func stroke(_ rect: CGRect, blendMode: CGBlendMode) {
        NSGraphicsContext.saveGraphicsState()
        cgContext.setBlendMode(blendMode)
        cgContext.stroke(rect)
        NSGraphicsContext.restoreGraphicsState()
    }
    
    public override init() {
        self.format = MacGraphicsImageRendererFormat()
        super.init()
    }
    
    public var currentImage: NSImage {
        guard let cgImage = cgContext.makeImage()
            else { fatalError("Cannot retrieve cgImage from current context") }
        return NSImage(cgImage: cgImage, size: format.bounds.size)
    }
}

public class MacGraphicsImageRenderer: NSObject {
    
    public class func context(with format: MacGraphicsImageRendererFormat) -> CGContext? {
        fatalError("Not implemented")
    }
    
    public class func prepare(_ context: CGContext, with: MacGraphicsImageRendererContext) {
        fatalError("Not implemented")
    }
    
    public class func rendererContextClass() {
        fatalError("Not implemented")
    }
    
    public var allowsImageOutput: Bool = true
    
    public let format: MacGraphicsImageRendererFormat
    
    public let bounds: CGRect
    
    public init(bounds: CGRect, format: MacGraphicsImageRendererFormat) {
        (self.bounds, self.format) = (bounds, format)
        self.format.bounds = self.bounds
        super.init()
    }
    
    public convenience init(size: CGSize, format: MacGraphicsImageRendererFormat) {
        self.init(bounds: CGRect(origin: .zero, size: size), format: format)
    }
    
    public convenience init(size: CGSize) {
        self.init(bounds: CGRect(origin: .zero, size: size), format: MacGraphicsImageRendererFormat())
    }
    
    public func image(actions: @escaping (MacGraphicsImageRendererContext) -> Void) -> NSImage {
        let image = NSImage(size: format.bounds.size, flipped: false) {
            (drawRect: NSRect) -> Bool in
            
            let imageContext = MacGraphicsImageRendererContext()
            imageContext.format = self.format
            actions(imageContext)
            
            return true
        }
        return image
    }
    
    public func pngData(actions: @escaping (MacGraphicsImageRendererContext) -> Void) -> Data {
        let image = self.image(actions: actions)
        var imageRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            else { fatalError("Could not construct PNG data from drawing request") }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size
        guard let data = bitmapRep.representation(using: .png, properties: [:])
            else { fatalError("Could not retrieve data from drawing request") }
        return data
    }
    
    public func jpegData(withCompressionQuality compressionQuality: CGFloat, actions: @escaping (MacGraphicsImageRendererContext) -> Void) -> Data {
        let image = self.image(actions: actions)
        var imageRect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            else { fatalError("Could not construct PNG data from drawing request") }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        bitmapRep.size = image.size
        guard let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
            else { fatalError("Could not retrieve data from drawing request") }
        return data
    }
    
    public func runDrawingActions(_ drawingActions: (MacGraphicsImageRendererContext) -> Void, completionActions: ((MacGraphicsImageRendererContext) -> Void)? = nil) throws {
        fatalError("Not implemented")
    }
}
#endif
