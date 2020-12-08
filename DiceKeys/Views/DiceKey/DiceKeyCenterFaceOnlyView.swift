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

    var diceKeySizeModel: DiceKeySizeModel {
        DiceKeySizeModel(size, hasTab: true)
    }
    
    var fractionalDistanceFromCenterToEdge: CGFloat {
        let radius: CGFloat = 1.0 / 8.0
        let distBeforeCurve: CGFloat = 0.5 - radius
        let distanceToCurveEdge = radius * CGFloat(sin(CGFloat.pi/4))
        return distBeforeCurve + distanceToCurveEdge
    }

    var originalFaceSize: CGFloat { diceKeySizeModel.faceSize }
    var magnifiedFaceSize: CGFloat { originalFaceSize * 2.75 }

    var originalFaceDistanceFromCenterToEdge: CGFloat {
        originalFaceSize * fractionalDistanceFromCenterToEdge
    }
    var magnifiedFaceDistanceFromCenterToEdge: CGFloat {
        magnifiedFaceSize * fractionalDistanceFromCenterToEdge
    }
    var magnifiedFaceOffset: CGPoint { CGPoint(
        x: -0.5 * magnifiedFaceSize,
        y: 0.5 * magnifiedFaceSize
    ) }
    var magnifiedFaceCenter: CGPoint { CGPoint(
        x: diceKeySizeModel.centerX + magnifiedFaceOffset.x,
        y: diceKeySizeModel.boxCenterY + magnifiedFaceOffset.y
    ) }

    var originalFaceLeft: CGFloat { diceKeySizeModel.centerX - originalFaceDistanceFromCenterToEdge }
    var originalFaceRight: CGFloat { diceKeySizeModel.centerX + originalFaceDistanceFromCenterToEdge }
    var originalFaceTop: CGFloat { diceKeySizeModel.boxCenterY - originalFaceDistanceFromCenterToEdge }
    var originalFaceBottom: CGFloat { diceKeySizeModel.boxCenterY + originalFaceDistanceFromCenterToEdge }
    var originalFaceTopLeft: CGPoint { CGPoint(x: originalFaceLeft, y: originalFaceTop) }
    var originalFaceTopRight: CGPoint { CGPoint(x: originalFaceRight, y: originalFaceTop) }
    var originalFaceBottomLeft: CGPoint { CGPoint(x: originalFaceLeft, y: originalFaceBottom) }
    var originalFaceBottomRight: CGPoint { CGPoint(x: originalFaceRight, y: originalFaceBottom) }
    var magnifiedFaceLeft: CGFloat { magnifiedFaceCenter.x - magnifiedFaceDistanceFromCenterToEdge }
    var magnifiedFaceRight: CGFloat { magnifiedFaceCenter.x + magnifiedFaceDistanceFromCenterToEdge }
    var magnifiedFaceTop: CGFloat { magnifiedFaceCenter.y - magnifiedFaceDistanceFromCenterToEdge }
    var magnifiedFaceBottom: CGFloat { magnifiedFaceCenter.y + magnifiedFaceDistanceFromCenterToEdge }
    var magnifiedFaceTopLeft: CGPoint { CGPoint(x: magnifiedFaceLeft, y: magnifiedFaceTop) }
    var magnifiedFaceTopRight: CGPoint { CGPoint(x: magnifiedFaceRight, y: magnifiedFaceTop) }
    var magnifiedFaceBottomLeft: CGPoint { CGPoint(x: magnifiedFaceLeft, y: magnifiedFaceBottom) }
    var magnifiedFaceBottomRight: CGPoint { CGPoint(x: magnifiedFaceRight, y: magnifiedFaceBottom) }

    var body: some View {
        CalculateBounds(bounds: $size) {
            ZStack(alignment: .center) {
                DiceKeyView(centerFace: centerFace, showLidTab: true, diceBoxColor: Color.alexandrasBlue, diceBoxDieSlotColor: Color.alexandrasBlue,
                            diePenColor: Color(red: 0, green: 0, blue: 0, opacity: 0.3),
                            faceSurfaceColor: .alexandrasBlueLighter
                    )
                    .frame(width: diceKeySizeModel.height, height: diceKeySizeModel.height)
                DieView(face: centerFace, dieSize: magnifiedFaceSize, faceBorderColor: Color.black)
                    .offset(x: magnifiedFaceOffset.x, y: magnifiedFaceOffset.y + diceKeySizeModel.offsetToBoxCenterY).hidden()
                Path { path in
                    path.move(to: originalFaceTopLeft)
                    path.addLine(to: magnifiedFaceTopLeft)
                    path.move(to: originalFaceTopRight)
                    path.addLine(to: magnifiedFaceTopRight)
                    path.move(to: originalFaceBottomLeft)
                    path.addLine(to: magnifiedFaceBottomLeft)
                    path.move(to: originalFaceBottomRight)
                    path.addLine(to: magnifiedFaceBottomRight)
                }.stroke(Color.gray, lineWidth: 2.0)
                .frame(width: diceKeySizeModel.width, height: diceKeySizeModel.height)
                DieView(face: centerFace, dieSize: magnifiedFaceSize, faceBorderColor: Color.black)
                    .offset(x: magnifiedFaceOffset.x, y: magnifiedFaceOffset.y + diceKeySizeModel.offsetToBoxCenterY)
            }
        }.aspectRatio(contentMode: .fit)
    }
}

struct DiceKeyCenterFaceOnlyView_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyCenterFaceOnlyView(centerFace: try! Face(fromHumanReadableForm: "A1t"))
    }
}
