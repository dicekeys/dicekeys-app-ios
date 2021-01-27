//
//  CameraFrameCountView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 26/01/21.
//

import SwiftUI

// This model tracks the frame count in an object that ScanDiceKey needn't
// observe, so that only the child that needs to render the frame count
// (CameraFrameCountView, below) refreshes on every frame.
class CameraFrameCountModel: ObservableObject {
    
    @Published var frameCount: Int = 0
}

struct CameraFrameCountView: View {
    
    @ObservedObject var cameraFrameCountModel: CameraFrameCountModel
    
    var body: some View {
        Text("\(cameraFrameCountModel.frameCount) frames processed").font(.footnote).foregroundColor(.white).padding(.top, 3)
    }
}
