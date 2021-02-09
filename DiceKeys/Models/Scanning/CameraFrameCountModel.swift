//
//  CameraFrameCountModel.swift
//  DiceKeys (iOS)
//
//  Created by Kevin Shah on 27/01/21.
//

import Foundation

// This model tracks the frame count in an object that ScanDiceKey needn't
// observe, so that only the child that needs to render the frame count
// (CameraFrameCountView, below) refreshes on every frame.
class CameraFrameCountModel: ObservableObject {
    
    @Published var frameCount: Int = 0
}
