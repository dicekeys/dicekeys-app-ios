//
//  DiceKeyCenterFaceOnlyView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/08.
//

import SwiftUI


struct DiceKeyCenterFaceOnlyView: View {
    var centerFace: Face

    @State var size: CGSize = .zero

    // Model of
    var fractionalDistanceFromCenterToCornerEdge: CGFloat {
        let radius: CGFloat = 1.0 / 8.0
        let distBeforeCurve: CGFloat = 0.5 - radius
        let distanceToCurveEdge = radius * CGFloat(sin(CGFloat.pi/4))
        return distBeforeCurve + distanceToCurveEdge
    }

    var faceMagnificationFactor: CGFloat { 4 }

    var magnifiedFaceFractionalOffset: CGPoint { CGPoint(
        x: 0,
        y: -0.7
    ) }

    // Use a unit model (fitting the DicKey box into 1x1 square bounds) to calculate the
    // extra space (overflow) required to inlucde any part of the magnified face that exceeds
    // those boounds
    let unitModel = DiceKeySizeModel(1, hasTab: true)
    var unitModelMagnifiedFaceSize: CGFloat { unitModel.faceSize * faceMagnificationFactor }

    var unitOverflowTop: CGFloat { max(0,
        -(unitModel.boxCenterY + (-0.5 + magnifiedFaceFractionalOffset.y) * unitModelMagnifiedFaceSize)
    ) }
    var unitOverflowBottom: CGFloat { max(0,
        (unitModel.boxCenterY + (0.5 + magnifiedFaceFractionalOffset.y) * unitModelMagnifiedFaceSize) - 1
    ) }
    var unitOverflowLeft: CGFloat { max(0,
                                        ( 0 - (unitModel.centerX + (-0.5 + magnifiedFaceFractionalOffset.x) * unitModelMagnifiedFaceSize) ) / unitModel.width
    ) }
    var unitOverflowRight: CGFloat { max(0,
                                         ( (unitModel.centerX + (0.5 + magnifiedFaceFractionalOffset.x) * unitModelMagnifiedFaceSize) - unitModel.width ) / unitModel.width
    ) }

    var unitOverflowHorizontal: CGFloat { unitOverflowLeft + unitOverflowRight }
    var unitOverflowVertical: CGFloat { unitOverflowTop + unitOverflowBottom }

    // Now create a DiceKey size model that nicludes space for that overlap
    var diceKeySizeModel: DiceKeySizeModel {
        DiceKeySizeModel(
            CGSize(
                width: size.width / (1 + unitOverflowHorizontal),
                height: size.height / (1 + unitOverflowVertical)
            ), hasTab: true
        )
    }

    var originalFaceSize: CGFloat { diceKeySizeModel.faceSize }
    var magnifiedFaceSize: CGFloat { diceKeySizeModel.faceSize * faceMagnificationFactor }

    var originalFaceDistanceFromCenterToCornerEdge: CGFloat {
        originalFaceSize * fractionalDistanceFromCenterToCornerEdge
    }
    var magnifiedFaceDistanceFromCenterToCornerEdge: CGFloat {
        magnifiedFaceSize * fractionalDistanceFromCenterToCornerEdge
    }

    var aspectRatio: CGFloat {
        (unitModel.width + unitOverflowHorizontal*unitModel.width) / (unitModel.height + unitOverflowVertical)
    }
    var totalWidth: CGFloat { min(size.width, diceKeySizeModel.width * (1 + unitOverflowHorizontal) ) }
    var totalHeight: CGFloat { min(size.height, diceKeySizeModel.height * (1 + unitOverflowVertical) ) }
    var offsetTop: CGFloat { diceKeySizeModel.height * unitOverflowTop }
    var offsetLeft: CGFloat { diceKeySizeModel.width * unitOverflowLeft }
    var offsetBottom: CGFloat { diceKeySizeModel.height * unitOverflowBottom }
    var offsetRight: CGFloat { diceKeySizeModel.width * unitOverflowRight }
    var offsetTopForCenteredObjects: CGFloat { (offsetTop / 2) - (offsetBottom / 2) }
    var offsetLeftForCenteredObjects: CGFloat { (offsetLeft / 2) - (offsetRight / 2) }

    var diceKeyBoxCenterX: CGFloat { offsetLeft + diceKeySizeModel.centerX }
    var diceKeyBoxCenterY: CGFloat { offsetTop + diceKeySizeModel.boxCenterY }

    var originalFaceCornerLeft: CGFloat { diceKeyBoxCenterX - originalFaceDistanceFromCenterToCornerEdge }
    var originalFaceCornerRight: CGFloat { diceKeyBoxCenterX + originalFaceDistanceFromCenterToCornerEdge }
    var originalFaceCornerTop: CGFloat { diceKeyBoxCenterY - originalFaceDistanceFromCenterToCornerEdge }
    var originalFaceCornerBottom: CGFloat { diceKeyBoxCenterY + originalFaceDistanceFromCenterToCornerEdge }
    var originalFaceCornerTopLeft: CGPoint { CGPoint(x: originalFaceCornerLeft, y: originalFaceCornerTop) }
    var originalFaceCornerTopRight: CGPoint { CGPoint(x: originalFaceCornerRight, y: originalFaceCornerTop) }
    var originalFaceCornerBottomLeft: CGPoint { CGPoint(x: originalFaceCornerLeft, y: originalFaceCornerBottom) }
    var originalFaceCornerBottomRight: CGPoint { CGPoint(x: originalFaceCornerRight, y: originalFaceCornerBottom) }

    var magnifiedFaceCenter: CGPoint { CGPoint(
        x: diceKeyBoxCenterX + magnifiedFaceFractionalOffset.x * magnifiedFaceSize,
        y: diceKeyBoxCenterY + magnifiedFaceFractionalOffset.y * magnifiedFaceSize
    ) }
    var magnifiedFaceCornerLeft: CGFloat { magnifiedFaceCenter.x - magnifiedFaceDistanceFromCenterToCornerEdge }
    var magnifiedFaceCornerRight: CGFloat { magnifiedFaceCenter.x + magnifiedFaceDistanceFromCenterToCornerEdge }
    var magnifiedFaceCornerTop: CGFloat { magnifiedFaceCenter.y - magnifiedFaceDistanceFromCenterToCornerEdge }
    var magnifiedFaceCornerBottom: CGFloat { magnifiedFaceCenter.y + magnifiedFaceDistanceFromCenterToCornerEdge }
    var magnifiedFaceCornerTopLeft: CGPoint { CGPoint(x: magnifiedFaceCornerLeft, y: magnifiedFaceCornerTop) }
    var magnifiedFaceCornerTopRight: CGPoint { CGPoint(x: magnifiedFaceCornerRight, y: magnifiedFaceCornerTop) }
    var magnifiedFaceCornerBottomLeft: CGPoint { CGPoint(x: magnifiedFaceCornerLeft, y: magnifiedFaceCornerBottom) }
    var magnifiedFaceCornerBottomRight: CGPoint { CGPoint(x: magnifiedFaceCornerRight, y: magnifiedFaceCornerBottom) }

    var body: some View {
        CalculateBounds(bounds: $size) {
            ZStack(alignment: .center) {
                //.overlay(
                    // The lines
                Path { path in
                    path.move(to: originalFaceCornerTopLeft)
                    path.addLine(to: magnifiedFaceCornerTopLeft)
                    path.move(to: originalFaceCornerTopRight)
                    path.addLine(to: magnifiedFaceCornerTopRight)
                    path.move(to: originalFaceCornerBottomLeft)
                    path.addLine(to: magnifiedFaceCornerBottomLeft)
                    path.move(to: originalFaceCornerBottomRight)
                    path.addLine(to: magnifiedFaceCornerBottomRight)
                }.stroke(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.5), lineWidth: max(diceKeySizeModel.linearSizeOfBox / 75, 2))
                    .frame(width: totalWidth, height: totalHeight)
                .background(
                    // The DiceKey box
                    DiceKeyView(centerFace: centerFace, showLidTab: true, diceBoxColor: Color.alexandrasBlue, diceBoxDieSlotColor: Color.alexandrasBlue,
                                diePenColor: Color(red: 0, green: 0, blue: 0, opacity: 0.3),
                                faceSurfaceColor: .alexandrasBlueLighter
                    )
                    .frame(width: diceKeySizeModel.width, height: diceKeySizeModel.height)
                    .offset(x: offsetLeftForCenteredObjects, y: offsetTopForCenteredObjects )
                ).overlay(
                    //)
                    // The magnfified die
                    DieView(face: centerFace, dieSize: magnifiedFaceSize, faceBorderColor: Color.black)
                        .offset(
                            x: offsetLeftForCenteredObjects + magnifiedFaceFractionalOffset.x * magnifiedFaceSize,
                            y: offsetTopForCenteredObjects + diceKeySizeModel.offsetToBoxCenterY + magnifiedFaceFractionalOffset.y * magnifiedFaceSize )
                        //.hidden()
                )
            }
        }.aspectRatio(self.aspectRatio, contentMode: .fit)
    }
}

struct DiceKeyCenterFaceOnlyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center) {
            DiceKeyCenterFaceOnlyView(centerFace: try! Face(fromHumanReadableForm: "A1t"))
        }
    }
}
