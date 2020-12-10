//
//  KeyScanningIllustration.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/10.
//

import SwiftUI

struct KeyScanningIllustration: View {
    var medium: DiceKeyMedium = .Dice

    @State var bounds: CGSize = .zero
    
    init(_ medium: DiceKeyMedium = .Dice) {
        self.medium = medium
    }

    let aspectRatio: CGFloat = 1.35
    
    // Render at arbitrary size. We'll rescale.
    var height: CGFloat { min(bounds.height, bounds.width / aspectRatio) }
    var width: CGFloat { min(bounds.width, aspectRatio * height) }

    var handImageHeight: CGFloat { 1.1 * height }
    var mediumImageHeightFraction: CGFloat { medium == .Dice ? 0.15 : 0.12 }
    var mediumImageHeight: CGFloat { height * mediumImageHeightFraction }
    var mediumImageXOffset: CGFloat {
        medium == .Dice ?
            -0.375 * height :
            -0.325 * height
    }

    var body: some View {
        CalculateBounds(bounds: $bounds) {
        ZStack(alignment: .center) {
            Image("Perspective Scanning Hand")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(height: handImageHeight)
                .offset(x: 0.1 * height, y: -0.275 * height)
            Image(medium == .Dice ? "Perspective DiceKey" : "Perspective Stickey")
                .resizable().aspectRatio(contentMode: .fit)
                .frame(height: mediumImageHeight)
                .offset(x: mediumImageXOffset, y: 0.425 * height)
        }.frame(width: width, height: height)
        }
        .aspectRatio(self.aspectRatio, contentMode: .fit)
    }
}

struct KeyScanningIllustration_Previews: PreviewProvider {
    static var previews: some View {
        KeyScanningIllustration()

        KeyScanningIllustration(.Stickers)
    }
}
