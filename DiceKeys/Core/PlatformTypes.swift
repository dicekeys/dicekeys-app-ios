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
#else
import AppKit

typealias XXView = NSView
typealias XXViewController = NSViewController
typealias XXViewControllerRepresentableContext = NSViewControllerRepresentableContext
#endif
