//
//  CameraFrameCountView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 26/01/21.
//

import SwiftUI

struct CameraFrameCountView: View {
    
    @ObservedObject var cameraFrameCountModel: CameraFrameCountModel
    
    var body: some View {
        Text("\(cameraFrameCountModel.frameCount) frames processed").font(.footnote).foregroundColor(.white).padding(.top, 3)
    }
}
