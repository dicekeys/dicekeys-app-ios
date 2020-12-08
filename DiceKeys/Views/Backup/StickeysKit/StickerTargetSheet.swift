//
//  StickerTargetSheet.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/02.
//

import SwiftUI

struct StickerTargetSheetSpecification {
    static let longSideOverShortSide = CGFloat(155.0/130.0)
    static let shortSideOverLongSide = 1/longSideOverShortSide
    static let lettersPerStickySheet = 5
}

struct StickerTargetSheet: View {
    let diceKey: DiceKey?
    var showLettersBeforeIndex: Int = 0
    var atDieIndex: Int?
    var foregroundColor: Color?

    @State private var bounds: CGSize = .zero

    enum Orientation: String {
        case landscape
        case portrait
    }
    var orientation: Orientation? = .portrait

    private var computedOrientation: Orientation {
        orientation ?? (
            bounds.height >= bounds.width ? .portrait : .landscape
        )
    }

    var width: CGFloat {
        min(
            bounds.width,
            bounds.height * ( computedOrientation != .landscape ? StickerTargetSheetSpecification.shortSideOverLongSide : StickerTargetSheetSpecification.longSideOverShortSide
            )
        )
    }
    var height: CGFloat {
        min(
            bounds.height,
            bounds.width * ( computedOrientation == .landscape ? StickerTargetSheetSpecification.shortSideOverLongSide : StickerTargetSheetSpecification.longSideOverShortSide
            )
        )
    }

    var shorterSideSize: CGFloat {
        min(width, height)
    }

    var faceSizeModel: DiceKeySizeModel { DiceKeySizeModel(shorterSideSize) }

    var faceSize: CGFloat { faceSizeModel.faceSize }
    var faceStepSize: CGFloat { faceSizeModel.stepSize }

    func offset(forFaceIndex faceIndex: Int) -> CGSize {
        let x = CGFloat(-2 + CGFloat(faceIndex % 5)) * faceStepSize
        let y = CGFloat(-2 + CGFloat(Int(faceIndex / 5))) * faceStepSize
        return CGSize(width: x, height: y)
    }

    let handImageWidthAsFractionOfFaceSize: CGFloat = 8.85
    var handImageHeightAsFractionOfFaceSize: CGFloat {
        // Using dimensions from within SVG file
        handImageWidthAsFractionOfFaceSize * CGFloat(187) / CGFloat(219)
    }
    var handImageWidth: CGFloat {
        faceSize * handImageWidthAsFractionOfFaceSize
    }
    var handImageHeight: CGFloat {
        faceSize * handImageHeightAsFractionOfFaceSize
    }
    var handImageOffsetToCenterOfDie: CGSize {
        CGSize(
            width: 0.3695 * handImageWidth,
            height: 0.2845 * handImageHeight
        )
    }
    var letterRange: Range<Int> {
        (0..<showLettersBeforeIndex)
    }

    var body: some View {
        CalculateBounds(bounds: $bounds) {
        ZStack(alignment: .center) {
            // The sheet
            Rectangle()
                .size(width: width, height: height)
                .fill(Color.white)
                .border(foregroundColor ?? Color.black)
//                .frame(width: width, height: height)
            // The dice
            ForEach(0..<25) { faceIndex in
                if faceIndex < showLettersBeforeIndex && diceKey != nil {
                    DieView(face: diceKey!.faces[faceIndex], dieSize: faceSize, penColor: foregroundColor ?? Color.black, faceBorderColor: foregroundColor ?? Color.gray)
                        .offset(self.offset(forFaceIndex: faceIndex))
                } else {
                    Image("Sticker Target")
                    .resizable()
                    .frame(width: faceSize, height: faceSize, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .offset(self.offset(forFaceIndex: faceIndex))
                }
            }
            if let atDieIndex = self.atDieIndex {
                if atDieIndex < 25 && atDieIndex >= 0 {
                    // Highlight-colored box
                    RoundedRectangle(cornerRadius: faceSize / 8)
                        .size(width: faceSize * 1.2, height: faceSize * 1.2)
                        .fill(Color.highlighter)
                        .offset(self.offset(forFaceIndex: atDieIndex))
                        .frame(width: faceSize * 1.2, height: faceSize * 1.2)
                    // Hand image
                    Image("Hand with Sticker")
                        .resizable()
                        .frame(width: handImageWidth, height: handImageHeight)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width, height: height)
                        .offset(handImageOffsetToCenterOfDie)
                        .offset(self.offset(forFaceIndex: atDieIndex))
                        //.mask(foregroundColor)
                    // Face being placed
                    if let diceKey = self.diceKey {
                        DieView(face: diceKey.faces[atDieIndex], dieSize: faceSize, penColor: foregroundColor ?? Color.black, faceSurfaceColor: Color.clear)
                            .offset(self.offset(forFaceIndex: atDieIndex))
                    }
                }
            }
//            VStack {
//                Text("B WxH = \(bounds.width) x \(bounds.height)").font(.footnote).background(Color.white)
//                Text("A WxH = \(width) x \(height)").font(.footnote).background(Color.white)
//            }
        }}.aspectRatio(computedOrientation == .landscape ? StickerTargetSheetSpecification.longSideOverShortSide : StickerTargetSheetSpecification.shortSideOverLongSide, contentMode: .fit)
    }
}

//struct StickerTargetSheet: View {
//    var diceKey: DiceKey?
//    var showLettersBeforeIndex: Int = 0
//    var highlightAtIndex: Int?
//
//    var body: some View {
//        GeometryReader { geometry in
//            StickerTargetSheetFixedSize(bounds: geometry.size, diceKey: diceKey, showLettersBeforeIndex: showLettersBeforeIndex, highlightAtIndex: highlightAtIndex)
//        }
//    }
//}

struct StickerTargetSheet_Previews: PreviewProvider {
    static var previews: some View {
        BackupToStickeysIntroduction(diceKey: DiceKey.createFromRandom())
                .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        GeometryReader { _ in
                StickerTargetSheet(
                    diceKey: DiceKey.createFromRandom(),
                    showLettersBeforeIndex: 13,
                    atDieIndex: 13
                ).scaledToFit()
        }.previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        StickerTargetSheet(
            diceKey: DiceKey.createFromRandom()
        ).frame(width: 300, height: 300).previewDevice(PreviewDevice(rawValue: "iPhone 8"))

        AppMainView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
