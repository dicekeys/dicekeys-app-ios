//
//  WindowDimensions.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation
import SwiftUI

struct WindowDimensions {
    #if os(iOS)
    static let shorterSide = UIScreen.main.bounds.size.shorterSide
    #else
    static let size: CGSize = CGSize(width: 480, height: 700)
    static let shorterSide = size.shorterSide
//    static let shorterSide = NSScreen.main!.frame.size.height
    #endif
}
