//
//  FacesReadOverlay.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/20.
//

import SwiftUI

struct AngularCoordinateSystem {
    private let zeroPoint: CGPoint
    private let cosAngle: CGFloat
    private let sinAngle: CGFloat
    
    init(zeroPoint: CGPoint, angle: Angle, scalingFactor: CGFloat) {
        self.zeroPoint = zeroPoint
        self.cosAngle = CGFloat(cos(angle.radians)) * scalingFactor
        self.sinAngle = CGFloat(sin(angle.radians)) * scalingFactor
    }

    public func pointAt(offset: CGPoint) -> CGPoint {
        CGPoint(
            x: zeroPoint.x + offset.x * cosAngle - offset.y * sinAngle,
            y: zeroPoint.y + offset.x * sinAngle + offset.y * cosAngle
        )
    }

//    func pointAtAsTuple(offset: Point): [number, number] => [
//    zeroPoint.x + offset.x * cosAngle - offset.y * sinAngle,
//    zeroPoint.y + offset.x * sinAngle + offset.y * cosAngle
//  ];
//  return {pointAtAsXy, pointAtAsTuple};
}

struct FaceReadOverlay: View {
    let faceRead: FaceRead
    let faceSizeInPixels: CGFloat
    let coordinateSystemFromCenterOfDie: AngularCoordinateSystem

    init(faceRead: FaceRead) {
        self.faceRead = faceRead
        faceSizeInPixels = faceRead.length ?? 0
        let angle = faceRead.angle ?? Angle(radians: 0)
        coordinateSystemFromCenterOfDie = AngularCoordinateSystem(zeroPoint: faceRead.center.cgPoint, angle: angle, scalingFactor: faceSizeInPixels)
    }

    var letterCenter: CGPoint {
        coordinateSystemFromCenterOfDie.pointAt(offset: CGPoint(
            x: -(FaceDimensionsFractional.textRegionWidth + FaceDimensionsFractional.spaceBetweenLetterAndDigit) / 2,
            y: 0 // dead center for text rendering
        ))
    }

    var digitCenter: CGPoint {
        coordinateSystemFromCenterOfDie.pointAt(offset: CGPoint(
            x: -(FaceDimensionsFractional.textRegionWidth + FaceDimensionsFractional.spaceBetweenLetterAndDigit) / 2,
            y: 0 // dead center for text rendering
        ))
    }

    var body: some View {
        ZStack {
            if let letter = faceRead.letter {
                Text(letter.rawValue).position(letterCenter)
            }
            if let digit = faceRead.digit {
                Text(digit.rawValue).position(digitCenter)
            }
        }
    }
}

struct FacesReadOverlay: View {
    let facesRead: [FaceReadIdentifiable]

    struct FaceReadIdentifiable: Identifiable {
        let indexInArray: Int
        var faceRead: FaceRead
        var id: Int { indexInArray }
    }

    var body: some View {
        ZStack {
            ForEach(facesRead) { fri in
                FaceReadOverlay(faceRead: fri.faceRead)
            }
        }
    }
}


//struct FacesReadOverlay_Previews: PreviewProvider {
//    static var previews: some View {
//        FacesReadOverlay()
//    }
//}
