//
//  FaceOrientationLetterTrbl.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/01/22.
//

import Foundation

extension FaceOrientationLetterTrbl {
    var right: FaceOrientationLetterTrbl {
        switch(self) {
        case .Top: return .Right
        case .Right: return .Bottom
        case .Bottom: return .Left
        case .Left: return .Top
        }
    }

    var left: FaceOrientationLetterTrbl {
        switch(self) {
        case .Top: return .Left
        case .Right: return .Top
        case .Bottom: return .Right
        case .Left: return .Bottom
        }
    }
}
