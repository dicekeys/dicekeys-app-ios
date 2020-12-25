//
//  RoundedRectCard.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/18.
//

import SwiftUI

struct RoundedRectCard<Content: View>: View {
    var backgroundRectColor: Color = Color.white
    var radius: CGFloat?
    var topMargin: CGFloat?
    var bottomMargin: CGFloat?
    var leftMargin: CGFloat?
    var rightMargin: CGFloat?
    var horizontalMargin: CGFloat = 5
    var verticalMargin: CGFloat = 5
    let content: () -> Content
    
    private var tMargin: CGFloat { topMargin ?? verticalMargin }
    private var bMargin: CGFloat { bottomMargin ?? verticalMargin }
    private var lMargin: CGFloat { leftMargin ?? horizontalMargin }
    private var rMargin: CGFloat { rightMargin ?? horizontalMargin }

    var calculatedRadius: CGFloat {
        radius ?? max(horizontalMargin, verticalMargin)
    }

    var body: some View {
  //      VStack(alignment: .leading, spacing: 0) {
        content()
            .padding(.top, tMargin)
            .padding(.leading, lMargin)
            .padding(.bottom, bMargin)
            .padding(.trailing, rMargin)
            .background(backgroundRectColor).cornerRadius(radius ?? 0)
//        }.background(backgroundRectColor).cornerRadius(radius ?? 0)
        
//        background( RoundedRectangle(cornerSize: CGSize(width: calculatedRadius, height: calculatedRadius), style: .circular).foregroundColor(backgroundRectColor) )
    }
}

struct RoundedRectCard_Previews: PreviewProvider {
    static var previews: some View {
        RoundedRectCard(backgroundRectColor: Color.black) { Text("Hello Whirled").foregroundColor(.white) }
    }
}
