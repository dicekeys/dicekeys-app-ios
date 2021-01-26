//
//  CameraFrameCountView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 26/01/21.
//

import SwiftUI

/// CameraFrameCountModel
class CameraFrameCountModel: ObservableObject {
    
    @Published var frameCount: Int = 0
}

struct CameraFrameCountView: View {
    
    @ObservedObject var cameraFrameCountModel: CameraFrameCountModel
    
    var body: some View {
        Text("\(cameraFrameCountModel.frameCount) frames processed").font(.footnote).foregroundColor(.white).padding(.top, 3)
    }
}
