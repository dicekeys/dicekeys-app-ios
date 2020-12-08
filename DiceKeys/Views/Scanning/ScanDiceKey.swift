//
//  ScanDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/24.
//

import SwiftUI

struct ScanDiceKey: View {
    var stickers: Bool = false
    let onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)?

    init(stickers: Bool = false, onDiceKeyRead: ((_ diceKey: DiceKey) -> Void)? = nil) {
        self.stickers = stickers
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
        VStack(alignment: .center, spacing: 0) {
            Text("Place the DiceKey so that the \(stickers ? "stickers" : "dice") fill the camera view. Then hold steady.").font(.title2)
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: 0) {
                    Spacer()
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
                    Spacer()
                }
                Text("\(frameCount) frames processed").font(.footnote).foregroundColor(.white).padding(.top, 3)
            }.background(Color.black).padding(.vertical, 5)
        }
    }
}

struct ScanDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        ScanDiceKey().previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
