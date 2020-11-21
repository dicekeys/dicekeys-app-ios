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
    let renderedSize: CGSize
    let imageFrameSize: CGSize
    let faceRead: FaceRead
    let faceSizeInPixels: CGFloat
    let angle: Angle
    let fontSize: CGFloat
    let coordinateSystemFromCenterOfDie: AngularCoordinateSystem

    init(renderedSize: CGSize, imageFrameSize: CGSize, faceRead: FaceRead) {
        self.renderedSize = renderedSize
        self.faceRead = faceRead
        self.imageFrameSize = imageFrameSize
        faceSizeInPixels = faceRead.length ?? 0
        fontSize = faceSizeInPixels * FaceDimensionsFractional.fontSize
        angle = faceRead.angle ?? Angle(radians: 0)
        coordinateSystemFromCenterOfDie = AngularCoordinateSystem(
            zeroPoint: CGPoint(x: renderedSize.height - faceRead.center.y, y: faceRead.center.x - 400),
            // zeroPoint: faceRead.center.cgPoint,
            angle: angle + Angle(degrees: 90), scalingFactor: faceSizeInPixels)
    }

    var letterCenter: CGPoint {
        coordinateSystemFromCenterOfDie.pointAt(offset: CGPoint(
            x: -(FaceDimensionsFractional.textRegionWidth/4 + FaceDimensionsFractional.spaceBetweenLetterAndDigit/2),
            y: 0 // dead center for text rendering
        ))
    }

    var digitCenter: CGPoint {
        coordinateSystemFromCenterOfDie.pointAt(offset: CGPoint(
            x: (FaceDimensionsFractional.textRegionWidth/4 + FaceDimensionsFractional.spaceBetweenLetterAndDigit/2),
            y: 0 // dead center for text rendering
        ))
    }

    var body: some View {
        ZStack {
            if let letter = faceRead.letter {
                Text(letter.rawValue)
                    .foregroundColor(.green)
                    .fontWeight(.bold)
                    .font(.custom("Inconsolata", size: fontSize))
                    .rotationEffect(angle + Angle(degrees: 90))
                    .position(letterCenter)
            }
            if let digit = faceRead.digit {
                Text(digit.rawValue)
                    .foregroundColor(.green)
                    .fontWeight(.bold)
                    .font(.custom("Inconsolata", size: fontSize))
                    .rotationEffect(angle + Angle(degrees: 90))
                    .position(digitCenter)
            }
        }
    }
}

struct FacesReadOverlay: View {
    let renderedSize: CGSize
    let imageFrameSize: CGSize

    let facesRead: [FaceRead]?

//        struct FaceReadIdentifiable: Identifiable {
//        let indexInArray: Int
//        var faceRead: FaceRead
//        var id: Int { indexInArray }
//    }

    var renderer: UIGraphicsImageRenderer {
        UIGraphicsImageRenderer(size: renderedSize)
    }

    private let letterColorSuccess = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private let letterOffset = CGPoint(
        x: -(FaceDimensionsFractional.textRegionWidth/4 + FaceDimensionsFractional.spaceBetweenLetterAndDigit/2),
        y: FaceDimensionsFractional.textBaselineY - 0.5 // bottom of text area to render
    )
    private let digitOffset = CGPoint(
        x: (FaceDimensionsFractional.textRegionWidth/4 + FaceDimensionsFractional.spaceBetweenLetterAndDigit/2),
        y: FaceDimensionsFractional.textBaselineY - 0.5 // bottom of text area to render
    )

    var body: some View {
        Image(uiImage: renderer.image { context in
            let cgContext = context.cgContext
            let frameRect = CGRect(x: 0, y: 0, width: renderedSize.width, height: renderedSize.height)
            cgContext.addRect(frameRect)
            cgContext.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
            cgContext.strokePath()
            guard let facesRead = self.facesRead else { return }

            for faceRead in facesRead {
                guard let faceSizeInFramePixels = faceRead.length else {
                    continue
                }
                guard let angle = faceRead.angle else {
                    continue
                }
                let faceSizeInPixels = faceSizeInFramePixels * renderedSize.width / imageFrameSize.width
                let fontSize = faceSizeInPixels * FaceDimensionsFractional.fontSize
                let coordinateSystemFromCenterOfDie = AngularCoordinateSystem(
                    zeroPoint: CGPoint(
                        x: faceRead.center.x * renderedSize.width / imageFrameSize.width,
                        y: faceRead.center.y * renderedSize.height / imageFrameSize.height
                    ),
//                        faceRead.center.cgPoint,
                    angle: angle, scalingFactor: faceSizeInPixels)

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let attrs = [
                    NSAttributedString.Key.font: UIFont(name: "Inconsolata-Bold", size: fontSize)!,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                    NSAttributedString.Key.foregroundColor: letterColorSuccess
                ]

                if let letter = faceRead.letter {
                    let letterCenter: CGPoint = coordinateSystemFromCenterOfDie.pointAt(offset: letterOffset)
                    // cgContext.saveGState()
                    cgContext.textMatrix = CGAffineTransform(translationX: letterCenter.x, y: letterCenter.y)
                        .rotated(by: CGFloat(angle.radians))
                        .scaledBy(x: 1, y: -1)
                    // cgContext.move(to: letterCenter)
                    // cgContext.rotate(by: CGFloat(angle.radians))
                    let attrString = NSAttributedString(string: letter.rawValue, attributes: attrs)
                    CTLineDraw(CTLineCreateWithAttributedString(attrString), cgContext)
                    // cgContext.restoreGState()
                }
                if let digit = faceRead.digit {
                    let digitCenter: CGPoint = coordinateSystemFromCenterOfDie.pointAt(offset: digitOffset)
                    cgContext.textMatrix = CGAffineTransform(translationX: digitCenter.x, y: digitCenter.y)
                        .rotated(by: CGFloat(angle.radians))
                        .scaledBy(x: 1, y: -1)
                    // cgContext.saveGState()
                    // cgContext.move(to: digitCenter)
                    // cgContext.rotate(by: CGFloat(angle.radians))
                    let attrString = NSAttributedString(string: digit.rawValue, attributes: attrs)
                    CTLineDraw(CTLineCreateWithAttributedString(attrString), cgContext)
                    // cgContext.restoreGState()
                }
            }
        })
        .frame(width: renderedSize.width, height: renderedSize.height)
        .position(x: renderedSize.width / 2, y: renderedSize.height / 2)
    }

    init(renderedSize: CGSize, imageFrameSize: CGSize, facesRead: [FaceRead]?) {
        self.renderedSize = renderedSize
        self.imageFrameSize = imageFrameSize
        self.facesRead = facesRead
//        self.facesRead = (facesRead ?? []).enumerated().map { index, faceRead in
//            FaceReadIdentifiable(indexInArray: index, faceRead: faceRead)
//        }
    }

//    var body: some View {
//        ZStack {
//            ForEach(facesRead) { fri in
//                FaceReadOverlay(renderedSize: renderedSize, imageFrameSize: imageFrameSize, faceRead: fri.faceRead)
//                    .frame(width: renderedSize.width, height: renderedSize.height)
//            }
//        }
//    }
}

let facesReadJson: String = """
    [{"underline": {"code": 168,"line": {"start": {"x": 38.017620, "y": 22.110001}, "end": {"x": 38.982380, "y": 82.889999}}}, "overline": {"code": 88,"line": {"start": {"x": 89.047318, "y": 21.049999}, "end": {"x": 90.452682, "y": 81.949997}}}, "center": {"x": 64.125000, "y": 52.000000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "RB", "ocrDigitCharsFromMostToLeastLikely": "65"},{"underline": {"code": 63,"line": {"start": {"x": 137.044617, "y": 19.990000}, "end": {"x": 137.955383, "y": 81.010002}}}, "overline": {"code": 203,"line": {"start": {"x": 189.017609, "y": 19.110001}, "end": {"x": 189.982391, "y": 79.889999}}}, "center": {"x": 163.500000, "y": 50.000000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "EB", "ocrDigitCharsFromMostToLeastLikely": "35"},{"underline": {"code": 139,"line": {"start": {"x": 236.516144, "y": 17.049999}, "end": {"x": 237.468475, "y": 78.949997}}}, "overline": {"code": 104,"line": {"start": {"x": 288.025299, "y": 16.080000}, "end": {"x": 289.474701, "y": 77.919998}}}, "center": {"x": 262.871155, "y": 47.500000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "NM", "ocrDigitCharsFromMostToLeastLikely": "14"},{"underline": {"code": 221,"line": {"start": {"x": 389.470306, "y": 76.010002}, "end": {"x": 388.544617, "y": 13.990000}}}, "overline": {"code": 48,"line": {"start": {"x": 337.474701, "y": 76.919998}, "end": {"x": 336.025299, "y": 15.080000}}}, "center": {"x": 362.878723, "y": 45.500000}, "orientationAsLowercaseLetterTrbl": "l","ocrLetterCharsFromMostToLeastLikely": "ZI", "ocrDigitCharsFromMostToLeastLikely": "65"},{"underline": {"code": 178,"line": {"start": {"x": 431.989990, "y": 69.955460}, "end": {"x": 495.010010, "y": 68.544540}}}, "overline": {"code": 77,"line": {"start": {"x": 432.019989, "y": 17.454088}, "end": {"x": 493.980011, "y": 16.045910}}}, "center": {"x": 463.250000, "y": 43.000000}, "orientationAsLowercaseLetterTrbl": "t","ocrLetterCharsFromMostToLeastLikely": "TI", "ocrDigitCharsFromMostToLeastLikely": "35"},{"underline": {"code": 57,"line": {"start": {"x": 40.017620, "y": 122.110001}, "end": {"x": 40.982380, "y": 182.889999}}}, "overline": {"code": 218,"line": {"start": {"x": 91.018387, "y": 121.139999}, "end": {"x": 91.997742, "y": 181.860001}}}, "center": {"x": 66.004028, "y": 152.000000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "DO", "ocrDigitCharsFromMostToLeastLikely": "35"},{"underline": {"code": 193,"line": {"start": {"x": 135.080002, "y": 175.967499}, "end": {"x": 195.919998, "y": 175.016876}}}, "overline": {"code": 52,"line": {"start": {"x": 134.050003, "y": 124.468475}, "end": {"x": 194.949997, "y": 123.531525}}}, "center": {"x": 165.000000, "y": 149.746094}, "orientationAsLowercaseLetterTrbl": "t","ocrLetterCharsFromMostToLeastLikely": "VY", "ocrDigitCharsFromMostToLeastLikely": "46"},{"underline": {"code": 123,"line": {"start": {"x": 293.920013, "y": 121.048752}, "end": {"x": 233.080002, "y": 122.474686}}}, "overline": {"code": 149,"line": {"start": {"x": 294.890015, "y": 173.017609}, "end": {"x": 234.110001, "y": 173.982391}}}, "center": {"x": 264.000000, "y": 147.630859}, "orientationAsLowercaseLetterTrbl": "b","ocrLetterCharsFromMostToLeastLikely": "LE", "ocrDigitCharsFromMostToLeastLikely": "65"},{"underline": {"code": 203,"line": {"start": {"x": 333.079987, "y": 171.974686}, "end": {"x": 394.920013, "y": 170.525314}}}, "overline": {"code": 61,"line": {"start": {"x": 332.079987, "y": 120.498123}, "end": {"x": 394.920013, "y": 119.025314}}}, "center": {"x": 363.750000, "y": 145.505859}, "orientationAsLowercaseLetterTrbl": "t","ocrLetterCharsFromMostToLeastLikely": "WN", "ocrDigitCharsFromMostToLeastLikely": "65"},{"underline": {"code": 11,"line": {"start": {"x": 490.968475, "y": 172.949997}, "end": {"x": 490.031525, "y": 112.050003}}}, "overline": {"code": 241,"line": {"start": {"x": 438.000000, "y": 173.889999}, "end": {"x": 438.000000, "y": 114.110001}}}, "center": {"x": 464.250000, "y": 143.250000}, "orientationAsLowercaseLetterTrbl": "l","ocrLetterCharsFromMostToLeastLikely": "AW", "ocrDigitCharsFromMostToLeastLikely": "23"},{"underline": {"code": 183,"line": {"start": {"x": 42.018387, "y": 221.139999}, "end": {"x": 42.981613, "y": 280.859985}}}, "overline": {"code": 65,"line": {"start": {"x": 93.018387, "y": 220.139999}, "end": {"x": 93.981613, "y": 279.859985}}}, "center": {"x": 68.000000, "y": 250.500000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "UO", "ocrDigitCharsFromMostToLeastLikely": "23"},{"underline": {"code": 172,"line": {"start": {"x": 140.517609, "y": 219.110001}, "end": {"x": 141.482391, "y": 279.890015}}}, "overline": {"code": 83,"line": {"start": {"x": 192.018387, "y": 218.139999}, "end": {"x": 192.981613, "y": 277.859985}}}, "center": {"x": 166.750000, "y": 248.750000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "SG", "ocrDigitCharsFromMostToLeastLikely": "35"},{"underline": {"code": 52,"line": {"start": {"x": 295.920013, "y": 220.516876}, "end": {"x": 235.080002, "y": 221.467499}}}, "overline": {"code": 197,"line": {"start": {"x": 295.920013, "y": 272.032501}, "end": {"x": 236.080002, "y": 272.967499}}}, "center": {"x": 265.750000, "y": 246.746094}, "orientationAsLowercaseLetterTrbl": "b","ocrLetterCharsFromMostToLeastLikely": "CG", "ocrDigitCharsFromMostToLeastLikely": "65"},{"underline": {"code": 157,"line": {"start": {"x": 395.950012, "y": 218.016144}, "end": {"x": 334.049988, "y": 218.968475}}}, "overline": {"code": 101,"line": {"start": {"x": 396.950012, "y": 270.016144}, "end": {"x": 335.049988, "y": 270.968475}}}, "center": {"x": 365.500000, "y": 244.492310}, "orientationAsLowercaseLetterTrbl": "b","ocrLetterCharsFromMostToLeastLikely": "PR", "ocrDigitCharsFromMostToLeastLikely": "43"},{"underline": {"code": 83,"line": {"start": {"x": 494.950012, "y": 216.031525}, "end": {"x": 434.049988, "y": 216.968475}}}, "overline": {"code": 171,"line": {"start": {"x": 495.920013, "y": 267.525299}, "end": {"x": 434.079987, "y": 268.974701}}}, "center": {"x": 464.750000, "y": 242.375000}, "orientationAsLowercaseLetterTrbl": "b","ocrLetterCharsFromMostToLeastLikely": "GO", "ocrDigitCharsFromMostToLeastLikely": "14"},{"underline": {"code": 124,"line": {"start": {"x": 44.033493, "y": 320.109985}, "end": {"x": 44.966507, "y": 378.890015}}}, "overline": {"code": 131,"line": {"start": {"x": 95.002792, "y": 318.170013}, "end": {"x": 95.997208, "y": 378.829987}}}, "center": {"x": 70.000000, "y": 349.000000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "MN", "ocrDigitCharsFromMostToLeastLikely": "14"},{"underline": {"code": 109,"line": {"start": {"x": 197.919998, "y": 321.048737}, "end": {"x": 137.080002, "y": 322.474701}}}, "overline": {"code": 152,"line": {"start": {"x": 198.889999, "y": 372.017609}, "end": {"x": 138.110001, "y": 372.982391}}}, "center": {"x": 168.000000, "y": 347.130859}, "orientationAsLowercaseLetterTrbl": "b","ocrLetterCharsFromMostToLeastLikely": "JI", "ocrDigitCharsFromMostToLeastLikely": "46"},{"underline": {"code": 91,"line": {"start": {"x": 237.110001, "y": 371.482391}, "end": {"x": 297.890015, "y": 370.517609}}}, "overline": {"code": 184,"line": {"start": {"x": 236.139999, "y": 320.497711}, "end": {"x": 296.859985, "y": 319.518433}}}, "center": {"x": 267.000000, "y": 345.504028}, "orientationAsLowercaseLetterTrbl": "t","ocrLetterCharsFromMostToLeastLikely": "HM", "ocrDigitCharsFromMostToLeastLikely": "14"},{"underline": {"code": 148,"line": {"start": {"x": 392.981567, "y": 372.859985}, "end": {"x": 392.018433, "y": 313.140015}}}, "overline": {"code": 113,"line": {"start": {"x": 340.981567, "y": 373.859985}, "end": {"x": 340.018433, "y": 314.140015}}}, "center": {"x": 366.500000, "y": 343.500000}, "orientationAsLowercaseLetterTrbl": "l","ocrLetterCharsFromMostToLeastLikely": "OD", "ocrDigitCharsFromMostToLeastLikely": "14"},{"underline": {"code": 103,"line": {"start": {"x": 495.920013, "y": 315.532501}, "end": {"x": 435.079987, "y": 316.483124}}}, "overline": {"code": 145,"line": {"start": {"x": 496.920013, "y": 366.516876}, "end": {"x": 436.079987, "y": 367.467499}}}, "center": {"x": 466.000000, "y": 341.500000}, "orientationAsLowercaseLetterTrbl": "b","ocrLetterCharsFromMostToLeastLikely": "IT", "ocrDigitCharsFromMostToLeastLikely": "56"},{"underline": {"code": 81,"line": {"start": {"x": 45.504181, "y": 417.170013}, "end": {"x": 46.971230, "y": 476.829987}}}, "overline": {"code": 177,"line": {"start": {"x": 96.531525, "y": 416.049988}, "end": {"x": 97.453094, "y": 475.950012}}}, "center": {"x": 71.615005, "y": 446.500000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "FE", "ocrDigitCharsFromMostToLeastLikely": "56"},{"underline": {"code": 215,"line": {"start": {"x": 144.002777, "y": 415.170013}, "end": {"x": 144.997223, "y": 475.829987}}}, "overline": {"code": 57,"line": {"start": {"x": 195.533478, "y": 415.109985}, "end": {"x": 196.482391, "y": 474.890015}}}, "center": {"x": 170.253967, "y": 445.250000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "YV", "ocrDigitCharsFromMostToLeastLikely": "65"},{"underline": {"code": 113,"line": {"start": {"x": 294.981567, "y": 472.859985}, "end": {"x": 294.018433, "y": 413.140015}}}, "overline": {"code": 156,"line": {"start": {"x": 243.467499, "y": 473.920013}, "end": {"x": 242.532501, "y": 414.079987}}}, "center": {"x": 268.750000, "y": 443.500000}, "orientationAsLowercaseLetterTrbl": "l","ocrLetterCharsFromMostToLeastLikely": "KR", "ocrDigitCharsFromMostToLeastLikely": "23"},{"underline": {"code": 205,"line": {"start": {"x": 394.466522, "y": 470.890015}, "end": {"x": 393.517609, "y": 411.109985}}}, "overline": {"code": 44,"line": {"start": {"x": 342.451263, "y": 471.920013}, "end": {"x": 341.048737, "y": 412.079987}}}, "center": {"x": 367.871033, "y": 441.500000}, "orientationAsLowercaseLetterTrbl": "l","ocrLetterCharsFromMostToLeastLikely": "XK", "ocrDigitCharsFromMostToLeastLikely": "23"},{"underline": {"code": 38,"line": {"start": {"x": 441.018433, "y": 410.140015}, "end": {"x": 441.981567, "y": 469.859985}}}, "overline": {"code": 195,"line": {"start": {"x": 492.532501, "y": 409.079987}, "end": {"x": 493.483124, "y": 469.920013}}}, "center": {"x": 467.253906, "y": 439.750000}, "orientationAsLowercaseLetterTrbl": "r","ocrLetterCharsFromMostToLeastLikely": "BD", "ocrDigitCharsFromMostToLeastLikely": "23"}]
"""

struct FacesReadOverlay_Previews: PreviewProvider {
    static var previews: some View {
        FacesReadOverlay(
            renderedSize: CGSize(width: 600, height: 600),
            imageFrameSize: CGSize(width: 600, height: 600),
            facesRead: FaceRead.fromJson(facesReadJson)!
        )
        .previewLayout(PreviewLayout.fixed(width: 600, height: 600))
    }
}
