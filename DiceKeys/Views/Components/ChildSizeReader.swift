//
//  ChildSizeReader.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/05.
//

import Foundation
import SwiftUI

//struct GeometryPreferenceKey: PreferenceKey {
//    typealias Value = GeometryProxy
//    static var defaultValue: Value = GeometryProxy.
//
//    static func reduce(value _: inout Value, nextValue: () -> Value) {
//        _ = nextValue()
//    }
//}
//
//struct WithGeometry<Content: View>: View {
//    @Binding var geometry: GeometryProxy
//    let contentBuilder: () -> Content
//
//    init(
//        geometry: Binding<GeometryProxy>,
//        @ViewBuilder contentBuilder: @escaping () -> Content
//    ) {
//        self._geometry = geometry
//        self.contentBuilder = contentBuilder
//    }
//
//    var body: some View {
//        GeometryReader { geometry in
//            contentBuilder()
//                .preference(key: SizePreferenceKey.self, value: geometry)
//                .onPreferenceChange(SizePreferenceKey.self) { preferences in
//                    self.geometry = preferences
//                }
//        }
//    }
//}

//struct SideEffectView: View {
//    init(_ actionWithSideEffects: () -> Void) {
//        actionWithSideEffects()
//    }
//    
//    var body: some View {
//        EmptyView()
//    }
//}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

struct CalculateBounds<Content: View>: View {
    @Binding var bounds: CGSize
    let contentBuilder: () -> Content

    init(
        bounds: Binding<CGSize>,
        @ViewBuilder contentBuilder: @escaping () -> Content
    ) {
        self._bounds = bounds
        self.contentBuilder = contentBuilder
    }

    var body: some View {
        GeometryReader { geometry in
            contentBuilder()
                .preference(key: SizePreferenceKey.self, value: geometry.size)
                .onPreferenceChange(SizePreferenceKey.self) { preferences in
                    self.bounds = preferences
                }
        }
    }
}

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

struct BoundsTest: View {
    @State var bounds: CGSize = .zero

    var body: some View {
        CalculateBounds(bounds: $bounds) {
            Text("Hello world \(bounds.height)").frame(maxHeight: bounds.height)
        }
    }
}

struct ChildSizeReader_Previews: PreviewProvider {
    static var previews: some View {
        BoundsTest()
    }
}
