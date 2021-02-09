//
//  FacesReadOverlayModel.swift
//  DiceKeys (iOS)
//
//  Created by Kevin Shah on 27/01/21.
//

import SwiftUI

// This model tracks the image frame size and facesRead in an object that ScanDiceKey needn't
// observe, so that only the child that needs to render
class FacesReadOverlayModel: ObservableObject {
    
    @Published var imageFrameSize: CGSize = .zero
    @Published var facesRead: [FaceRead] = []
}
