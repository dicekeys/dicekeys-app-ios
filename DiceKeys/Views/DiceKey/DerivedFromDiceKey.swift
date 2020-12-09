//
//  DerivedFromDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/26.
//

import SwiftUI

struct DiceKeyFunnel: View {
    var diceKey: DiceKey?
    let diceKeySize: CGFloat
    var bottomWidth: CGFloat
    var contentHeight: CGFloat

    var funnelTopPadding: CGFloat { diceKeySize / 40 }
    var funnelHeight: CGFloat { diceKeySize * 0.3 }
    var verticalOverlap: CGFloat { diceKeySize / 30 }
    var totalFunnelHeight: CGFloat { funnelHeight + funnelTopPadding + contentHeight }
    var totalHeight: CGFloat { diceKeySize + totalFunnelHeight - verticalOverlap }

    var bottleneckFractionFromTop: CGFloat = 0.75

    var topWidth: CGFloat { self.diceKeySize }
    var width: CGFloat {
        max(topWidth, bottomWidth)
    }

    var bottleneckWidth: CGFloat { diceKeySize / 4 }

    var arrowSize: CGFloat { min( funnelHeight, bottleneckWidth * 0.8 ) }

    var body: some View {
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
        }.frame(height: totalHeight)
    }
}

struct DerivedFromDiceKey<Content: View>: View {
    let diceKey: DiceKey
    let diceKeySize: CGFloat?
    let diceKeySizeFraction: CGFloat
    let content: () -> Content

//    @State var funnelSize: CGSize = .zero
    @State var contentSize: CGSize = .zero
    @State var funnelSize: CGSize = .zero // UIScreen.main.bounds.size

    var frameSize: CGSize {
        if contentSize == .zero || funnelSize == .zero {
            return UIScreen.main.bounds.size
        } else {
            return funnelSize
        }
    }

    init(diceKey: DiceKey, diceKeySize: CGFloat? = nil, diceKeySizeFraction: CGFloat = 0.75, @ViewBuilder content: @escaping () -> Content) {
        self.diceKey = diceKey
        self.diceKeySize = diceKeySize
        self.diceKeySizeFraction = diceKeySizeFraction
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ChildSizeReader<DiceKeyFunnel>(size: $funnelSize) {
                    DiceKeyFunnel(diceKey: diceKey, diceKeySize: diceKeySize ?? (geometry.size.width  * diceKeySizeFraction), bottomWidth: contentSize.width, contentHeight: contentSize.height)
                }
                ChildSizeReader<Content>(size: $contentSize, content: content)
            }
        }.frame(width: frameSize.width, height: frameSize.height)
    }
}

struct DerivedFromDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            DiceKeyFunnel(diceKeySize: 600, bottomWidth: 1000, contentHeight: 100)
                .previewLayout(.fixed(width: 1000, height: 1000))
                .background(Color.green)
            Spacer()
        }.background(Color.yellow).previewDevice(PreviewDevice(rawValue: "iPad (8th generation)"))

        VStack {
            DerivedFromDiceKey(diceKey: DiceKey.createFromRandom(), diceKeySizeFraction: 0.5) {
                    Text("Somethign short").multilineTextAlignment(.center).padding(.horizontal, 5)
            }.background(Color.green)
            Spacer()
        }.background(Color.yellow).previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))

        VStack {
            DerivedFromDiceKey(diceKey: DiceKey.createFromRandom()) {
                Text("some random words constitute your password and some more random words to be copied").multilineTextAlignment(.center).padding(.horizontal, 5)
            }.background(Color.green)
            Spacer()
            Text("I've hit rock bottom")
        }.background(Color.yellow).previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
