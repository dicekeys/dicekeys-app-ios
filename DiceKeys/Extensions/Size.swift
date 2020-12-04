//
//  Size.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/02.
//

import Foundation
import SwiftUI

extension CGSize {
    var shorterSide: CGFloat {
        min(width, height)
    }
    var longerSide: CGFloat {
        min(width, height)
    }
}
