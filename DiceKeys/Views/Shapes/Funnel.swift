//
//  Funnel.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/26.
//

import SwiftUI

func funnel(
    height: CGFloat,
    topWidth: CGFloat,
    bottomWidth: CGFloat,
    bottleneckWidth bottleneckWidthOrNil: CGFloat? = nil,
    paddingTop: CGFloat = 0,
    paddingBottom: CGFloat = 0,
    bottleneckFractionFromTop: CGFloat = 0.6,
    curvature: CGFloat = 0.4
) -> Path {
    var path = Path()

    let bottleneckWidth = bottleneckWidthOrNil ?? (topWidth / 5)
    let invCurvature = 1 - curvature

    let centerX = max(topWidth, bottomWidth) / 2

    let topLeft = centerX - topWidth / 2
    let topRight = centerX + topWidth / 2
    let bottomLeft = centerX - bottomWidth / 2
    let bottomRight = centerX + bottomWidth / 2
    let bottleneckLeft = centerX - bottleneckWidth / 2
    let bottleneckRight = centerX + bottleneckWidth / 2

    let paddingTopY: CGFloat = 0
    let top: CGFloat = paddingTop
    let bottom: CGFloat = top + height
    let paddingBottomY: CGFloat = bottom + paddingBottom

    let  bottleneckY = top + height * bottleneckFractionFromTop

    path.move(to: CGPoint(x: topLeft, y: paddingTopY))
    path.addLine(to: CGPoint(x: topLeft, y: top))
    path.addCurve(
        to: CGPoint(x: bottleneckLeft, y: bottleneckY),
        control1: CGPoint(x: topLeft, y: top + (bottleneckY - top) * invCurvature ),
        control2: CGPoint(x: bottleneckLeft, y: top + (bottleneckY - top) * curvature)
    )
    path.addCurve(
        to: CGPoint(x: bottomLeft, y: bottom),
        control1: CGPoint(x: bottleneckLeft, y: bottleneckY + (bottom - bottleneckY) * invCurvature),
        control2: CGPoint(x: bottomLeft, y: bottleneckY + (bottom - bottleneckY) * curvature)
    )
    path.addLine(to: CGPoint(x: bottomLeft, y: paddingBottomY))
    path.addLine(to: CGPoint(x: bottomRight, y: paddingBottomY))
    path.addLine(to: CGPoint(x: bottomRight, y: bottom))
    path.addCurve(
        to: CGPoint(x: bottleneckRight, y: bottleneckY),
        control1: CGPoint(x: bottomRight, y: bottleneckY + (bottom - bottleneckY) * curvature),
        control2: CGPoint(x: bottleneckRight, y: bottleneckY + (bottom - bottleneckY) * invCurvature)
    )
    path.addCurve(
        to: CGPoint(x: topRight, y: top),
        control1: CGPoint(x: bottleneckRight, y: top + (bottleneckY - top) * curvature),
        control2: CGPoint(x: topRight, y: top + (bottleneckY - top) * invCurvature )
    )
    path.addLine(to: CGPoint(x: topRight, y: paddingTopY))
    path.addLine(to: CGPoint(x: topLeft, y: paddingTopY))

    return path
}

struct Funnel: Shape {
    var topWidth: CGFloat?
    var bottomWidth: CGFloat?
    var bottleneckWidth: CGFloat?
    var paddingTop: CGFloat?
    var paddingBottom: CGFloat?
    var bottleneckFractionFromTop: CGFloat = 0.7
    var curvature: CGFloat = 0.5

    func path(in rect: CGRect) -> Path {
        funnel(
            height: (rect.height - (paddingTop ?? 0) - (paddingBottom ?? 0)),
            topWidth: min(topWidth ?? rect.width, rect.width),
            bottomWidth: min(bottomWidth ?? rect.width, rect.width),
            bottleneckWidth: bottleneckWidth == nil ? nil : min(bottleneckWidth!, rect.width),
            paddingTop: paddingTop ?? 0,
            paddingBottom: paddingBottom ?? 0,
            bottleneckFractionFromTop: bottleneckFractionFromTop,
            curvature: curvature)
    }
}

struct FunnelContainer<Content: View>: View {
    var topWidth: CGFloat?
    var bottomWidth: CGFloat?
    var bottleneckWidth: CGFloat?
    var paddingTop: CGFloat?
    var paddingBottom: CGFloat?
    var bottleneckFractionFromTop: CGFloat = 0.7
    var curvature: CGFloat = 0.5

    let content: (() -> Content)?

    @State var contentSize: CGSize = .zero

    init(
        topWidth: CGFloat? = nil,
        bottomWidth: CGFloat? = nil,
        bottleneckWidth: CGFloat? = nil,
        paddingTop: CGFloat? = nil,
        paddingBottom: CGFloat? = nil,
        bottleneckFractionFromTop: CGFloat = 0.7,
        curvature: CGFloat = 0.5,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() as! Content }
    ) {
        self.topWidth = topWidth
        self.bottomWidth = bottomWidth
        self.bottleneckWidth = bottleneckWidth
        self.paddingTop = paddingTop
        self.paddingBottom = paddingBottom
        self.bottleneckFractionFromTop = bottleneckFractionFromTop
        self.curvature = curvature
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Funnel(
                topWidth: topWidth,
                bottomWidth: bottomWidth ?? contentSize.width,
                bottleneckWidth: bottleneckWidth,
                paddingTop: paddingTop,
                paddingBottom: contentSize.height + (paddingBottom ?? 0),
                bottleneckFractionFromTop: bottleneckFractionFromTop,
                curvature: curvature
            ).stroke(/*@START_MENU_TOKEN@*/Color.blue/*@END_MENU_TOKEN@*/, lineWidth: 1.0)
            if let nonNilContent = self.content {
                ChildSizeReader<Content>(size: $contentSize, content: nonNilContent)
            }
        }
    }
}

struct Funnel_Previews: PreviewProvider {
    static var previews: some View {
        Funnel()

        FunnelContainer<Text> {
            Text("Hello Funnel")
        }
    }
}
