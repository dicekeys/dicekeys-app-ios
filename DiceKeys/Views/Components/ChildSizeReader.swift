//
//  ChildSizeReader.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/05.
//

import Foundation
import SwiftUI

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
