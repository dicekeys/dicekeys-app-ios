//
//  DerivedFromDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/26.
//

import SwiftUI

struct DiceKeyFunnel: View {
    var diceKey: DiceKey?
    @State var bounds: CGSize = .zero

    var bottomWidth: CGFloat
    var contentHeight: CGFloat

    var verticalOverlapAsFractionOfDiceKeySize: CGFloat = 1/30
    var funnelHeightAsFractionOfDiceKeySize: CGFloat = 0.3
    var maxDiceKeySizeAsFractionOfVerticalSpaceAboveContent: CGFloat { 1.0 / (1 + funnelHeightAsFractionOfDiceKeySize -  verticalOverlapAsFractionOfDiceKeySize) }
    var diceKeySize: CGFloat { max(0, min(
        bounds.width * 0.75,
        maxDiceKeySizeAsFractionOfVerticalSpaceAboveContent * (bounds.height - contentHeight - funnelBottomPadding) ) )
    }
    var funnelBottomPadding: CGFloat { 5 }

    var funnelHeight: CGFloat { diceKeySize * funnelHeightAsFractionOfDiceKeySize }
    var verticalOverlap: CGFloat { verticalOverlapAsFractionOfDiceKeySize * diceKeySize }
    var totalFunnelHeight: CGFloat { funnelHeight + funnelBottomPadding + contentHeight }
    var totalHeight: CGFloat { max(0, diceKeySize + totalFunnelHeight - verticalOverlap) }

    var bottleneckFractionFromTop: CGFloat = 0.75

    var topWidth: CGFloat { self.diceKeySize }
    var width: CGFloat {
        max(topWidth, bottomWidth)
    }

    var bottleneckWidth: CGFloat { diceKeySize / 4 }

    var arrowSize: CGFloat { min( funnelHeight, bottleneckWidth * 0.8 ) }

    var body: some View {
        CalculateBounds(bounds: $bounds) {
        HStack {
            Spacer()
                VStack(alignment: .center, spacing: 0) {
                    DiceKeyView(
                        diceKey: diceKey ?? DiceKey.createFromRandom(),
                        showLidTab: false,
                        leaveSpaceForTab: false,
                        diceBoxColor: Color.diceBox
                    )
                    // Frame to size
                    .frame(width: diceKeySize, height: diceKeySize)
                    // Remove the part to hide
                    .frame(height: diceKeySize - verticalOverlap, alignment: .top).clipped()
                    ZStack {
                        Funnel(topWidth: diceKeySize, bottomWidth: bottomWidth, bottleneckWidth: bottleneckWidth, paddingBottom: contentHeight, bottleneckFractionFromTop: bottleneckFractionFromTop)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.diceBox, .white]), startPoint: .top, endPoint: .bottom))
                            .frame(width: width, height: totalFunnelHeight, alignment: .center)
                        Funnel(topWidth: diceKeySize, bottomWidth: bottomWidth, bottleneckWidth: bottleneckWidth, paddingBottom: contentHeight, bottleneckFractionFromTop: bottleneckFractionFromTop)
                            .stroke(lineWidth: 1)
                            .foregroundColor(Color.diceBox)
                            .frame(width: width, height: totalFunnelHeight, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        Image(systemName: "arrow.down").resizable().frame(width: arrowSize, height: arrowSize, alignment: .bottom).foregroundColor(.yellow)
                            .offset(x: 0, y: -contentHeight/2 )
                    }
                }.frame(height: totalHeight)
            Spacer()
        }.frame(height: totalHeight)}
    }
}

struct DerivedFromDiceKey<Content: View>: View {
    let diceKey: DiceKey
    let content: () -> Content

    @State var contentSize: CGSize = .zero

    init(diceKey: DiceKey, @ViewBuilder content: @escaping () -> Content) {
        self.diceKey = diceKey
        self.content = content
    }

    var body: some View {
        DiceKeyFunnel(diceKey: diceKey, bottomWidth: contentSize.width, contentHeight: contentSize.height)
        .overlay(
            VStack(alignment: .center, spacing: 0) {
                Spacer()
                ChildSizeReader<Content>(size: $contentSize, content: content)
            }
        ).aspectRatio(contentMode: .fit)
    }
}

struct DerivedFromDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            DiceKeyFunnel(bottomWidth: 794, contentHeight: 100)
                .aspectRatio(contentMode: .fit)
                .previewLayout(.fixed(width: 1000, height: 1000))
                .background(Color.green)
            Spacer()
        }.background(Color.yellow).previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))

        VStack {
            Spacer()
            DerivedFromDiceKey(diceKey: DiceKey.createFromRandom()) {
                    Text("Somethign short").multilineTextAlignment(.center).padding(.horizontal, 5)
            }.background(Color.green)
            Spacer()
        }.frame(maxWidth: 200)
        .clipped()
        .background(Color.yellow)
        .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        VStack {
            Spacer()
            DerivedFromDiceKey(diceKey: DiceKey.createFromRandom()) {
                    Text("Somethign short").multilineTextAlignment(.center).padding(.horizontal, 5)
            }.background(Color.green)
            Spacer()
        }.frame(maxHeight: 200).clipped().background(Color.yellow).previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        VStack {
            DerivedFromDiceKey(diceKey: DiceKey.createFromRandom()) {
                Text("some random words constitute your password and some more random words to be copied").multilineTextAlignment(.center).padding(.horizontal, 5)
            }.background(Color.green)
            Spacer()
            Text("I've hit rock bottom")
        }.background(Color.yellow).previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
