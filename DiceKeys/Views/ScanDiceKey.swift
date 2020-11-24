//
//  ScanDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct ScanDiceKey: View {
    let onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)?

    init(onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)? = nil) {
        self.onDiceKeyRead = onDiceKeyRead
    }

    @State var frameCount: Int = 0
    @State var facesRead: [FaceRead]?
    @State var processedImageFrameSize: CGSize?

    func onFrameProcessed(_ processedImageFrameSize: CGSize, _ facesRead: [FaceRead]?) {
        self.frameCount += 1
        self.processedImageFrameSize = processedImageFrameSize
        self.facesRead = facesRead
        if facesRead?.count == 25 && facesRead?.allSatisfy({ faceRead in faceRead.errors.count == 0 }) == true {
            try? onDiceKeyRead?(DiceKey(facesRead!).rotatedClockwise90Degrees())
        }
    }

    var body: some View {
        VStack {
            Text("\(frameCount) frames processed")
            GeometryReader { reader in
                ZStack {
                    DiceKeysCameraView(onFrameProcessed: onFrameProcessed, size: reader.size)

                    FacesReadOverlay(
                        renderedSize: reader.size,
                        imageFrameSize: processedImageFrameSize ?? reader.size,
                        facesRead: self.facesRead
                    )
                }
            }.aspectRatio(1, contentMode: .fit)
        }
    }
}


struct ScanDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        ScanDiceKey()
    }
}
