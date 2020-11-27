//
//  DerivedFromDiceKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/26.
//

import SwiftUI

struct ChildSizeReader<Content: View>: View {
    @Binding var size: CGSize
    let content: () -> Content

    var body: some View {
        ZStack {
            content()
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: geometry.size)
                    }
                )
        }
        .onPreferenceChange(SizePreferenceKey.self) { preferences in
            self.size = preferences
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct DiceKeyFunnel: View {
    var diceKey: DiceKey?
    let diceKeySize: CGFloat
    var bottomWidth: CGFloat
    var contentHeight: CGFloat

    var bottleneckFractionFromTop: CGFloat = 0.75
    var funnelTopPadding: CGFloat { diceKeySize / 40 }
    var funnelHeight: CGFloat { diceKeySize / 3 }
    var verticalOverlap: CGFloat { diceKeySize / 30 }
    var totalFunnelHeight: CGFloat { funnelHeight + funnelTopPadding + contentHeight }

    var totalHeight: CGFloat { diceKeySize + totalFunnelHeight - verticalOverlap }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            DiceKeyViewFixedSize(
                diceKey: diceKey ?? DiceKey.createFromRandom(),
                viewSize: CGSize(width: diceKeySize, height: diceKeySize),
                showLidTab: false,
                leaveSpaceForTab: false,
                diceBoxColor: Colors.diceBox
            ).frame(height: diceKeySize - verticalOverlap, alignment: .top)
            .clipped()
            ZStack {
                Funnel(topWidth: diceKeySize, bottomWidth: bottomWidth, paddingBottom: contentHeight, bottleneckFractionFromTop: bottleneckFractionFromTop)
                    .fill(LinearGradient(gradient: Gradient(colors: [Colors.diceBox, .white]), startPoint: .top, endPoint: .bottom))
                    .frame(width: bottomWidth, height: totalFunnelHeight, alignment: .center)
                Funnel(topWidth: diceKeySize, bottomWidth: bottomWidth, paddingBottom: contentHeight, bottleneckFractionFromTop: bottleneckFractionFromTop)
                    .stroke(lineWidth: 1)
                    .foregroundColor(Colors.diceBox)
                    .frame(width: bottomWidth, height: totalFunnelHeight, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
        }.frame(height: totalHeight)
    }
}

struct DerivedFromDiceKey<Content: View>: View {
    let diceKey: DiceKey
    let content: () -> Content

//    @State var funnelSize: CGSize = .zero
    @State var contentSize: CGSize = .zero

    init(diceKey: DiceKey, @ViewBuilder content: @escaping () -> Content) {
        self.diceKey = diceKey
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
//            ChildSizeReader(size: $funnelSize) {
                DiceKeyFunnel(diceKey: diceKey, diceKeySize: 360, bottomWidth: contentSize.width, contentHeight: contentSize.height)
//            }
            ChildSizeReader<Content>(size: $contentSize, content: content)
        }
    }
}

struct DerivedFromDiceKey_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyFunnel(diceKeySize: 600, bottomWidth: 1000, contentHeight: 100)
            .previewLayout(.fixed(width: 1000, height: 1000))
            .background(Color.yellow)

        DerivedFromDiceKey(diceKey: DiceKey.createFromRandom()) {
            Text("some random words constitute your password and some more random words to be copied").multilineTextAlignment(.center).padding(.horizontal, 5)
        }
    }
}
