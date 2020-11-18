//
//  DiceKeyView.swift
//  
//
//  Created by Stuart Schechter on 2020/11/18.
//

import SwiftUI

fileprivate struct DieLidView: View {
    let radius: CGFloat
    let color: Color
    
    var body: some View {
        return Path { path in
            path.addArc(center: CGPoint(x: radius, y: 0), radius: radius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 180), clockwise: false)
        }
        .fill(color)
        .frame(width: 2 * radius, height: radius)
    }
    
}

struct DiceKeyView: View {
    let diceKey: DiceKey
    let viewSize: CGSize
    let showLidTab: Bool // = false
    let leaveSpaceForTab: Bool = false
    let diceBoxColor: Color = Color(red: 0x05 / 0xFF, green: 0x03 / 0xFF, blue: 0x50 / 0xFF)


    let fractionOfVerticalSpaceRequiredForTab: CGFloat = 0.1
    
    var fractionOfVerticalSpaceUsedByTab: CGFloat {
        (leaveSpaceForTab || showLidTab) ? fractionOfVerticalSpaceRequiredForTab : 0;
    }
    
    var fractionOfVerticalSpaceUsedByBox: CGFloat {
        1 - fractionOfVerticalSpaceUsedByTab
    }

    var linearSizeOfBox: CGFloat {
        min(viewSize.width, viewSize.height * fractionOfVerticalSpaceUsedByBox)
    }
    var lidTabRadius: CGFloat {
        fractionOfVerticalSpaceUsedByTab * viewSize.height
    }
    var boxCornerRadius: CGFloat {
        linearSizeOfBox / 50;
    }
    
    var width: CGFloat { linearSizeOfBox }
    var height: CGFloat { linearSizeOfBox + lidTabRadius }
    var hCenter: CGFloat { linearSizeOfBox / 2 }
    var vCenter: CGFloat { linearSizeOfBox / 2 }
    
//    var boxLeftEdge: CGFloat { (viewSize.width - linearSizeOfBox) / 2 }
//    var boxTopEdge: CGFloat { (viewSize.height - linearSizeOfBox) / 2 }

    let marginOfBoxEdgeAsFractionOfDieSize: CGFloat = 1/8;
    let distanceBetweenDiceAsFractionOfDieSize: CGFloat = 0.2
    var dieSize: CGFloat { return ( linearSizeOfBox / (
      5 +
      4 * distanceBetweenDiceAsFractionOfDieSize +
      2 * marginOfBoxEdgeAsFractionOfDieSize
    ) ) }
    
//    var leftmostDieCenter: CGFloat { boxLeftEdge + marginOfBoxEdgeAsFractionOfDieSize * dieSize + dieSize / 2 }
//    var topmostDieCenter: CGFloat { boxTopEdge + marginOfBoxEdgeAsFractionOfDieSize * dieSize + dieSize / 2 }
    var dieStepSize: CGFloat { (1 + distanceBetweenDiceAsFractionOfDieSize) * dieSize }

    private struct DiePosition: Identifiable {
        let indexInArray: Int
        var face: Face
        var id: Int { indexInArray }
        var column: Int { indexInArray % 5 }
        var row: Int { indexInArray / 5 }
    }
    
    private var facePositions: [DiePosition] {
        return Array<Int>(0...24).map { index in
            DiePosition(indexInArray: index, face: diceKey.faces[index] )
        }
    }
    
    var body: some View {
        ZStack {
            // The box
            RoundedRectangle(cornerRadius: boxCornerRadius)
                .size(width: linearSizeOfBox, height: linearSizeOfBox)
                .fill(diceBoxColor)
            // The lid
            if (showLidTab) {
                DieLidView(radius: lidTabRadius, color: diceBoxColor)
                .position(x: hCenter, y: vCenter + linearSizeOfBox/2 + lidTabRadius/2)
            }
            // The dice
            ForEach(facePositions) { facePosition in
                DieFaceView(face: facePosition.face, dieSize: dieSize)
                    .position(
                        x: hCenter + CGFloat(-2 + facePosition.column) * dieStepSize,
                        y: vCenter + CGFloat(-2 + facePosition.row) * dieStepSize
                    )
            }
        }.frame(width: width, height: height)
    }
}


struct DiceKeyView_Previews: PreviewProvider {
//    let diceKey: DiceKey = DiceKey.createFromRandom()
    
    static var previews: some View {
        DieLidView(radius: 300, color: Color.blue)
        
        DiceKeyView(diceKey: DiceKey.createFromRandom(), viewSize: CGSize(width: 600, height: 600), showLidTab: true)
            .background(Color.yellow)
    }
}
