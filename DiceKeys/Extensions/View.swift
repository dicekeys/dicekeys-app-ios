//
//  View.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/25.
//

import Foundation
import SwiftUI

extension View {
    func modifyIf(_ condition: Bool, _ modifier: (Self) -> Self) -> Self {
        return condition ? modifier(self) : self
    }
    
    #if os(iOS)
    func modifyIfIOS<Content: View>(
        _ modifier: (Self) -> Content
    ) -> Content {
        return modifier(self)
    }
    #else
    func modifyIfIOS(
        _ modifier: (Self) -> Any
    ) -> Self {
        return self
    }
    #endif

    func `if`<Content: View>(_ conditional: Bool, content: (Self) -> Content) -> some View {
         if conditional {
             return AnyView(content(self))
         } else {
             return AnyView(self)
         }
     }

    @ViewBuilder func hideIf(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }

    @ViewBuilder func showIf(_ show: Bool) -> some View {
        if show {
            self
        } else {
            self.hidden()
        }
    }
        
    @ViewBuilder func previewLayoutMinSupported() -> some View {
        // https://28b.co.uk/ios-device-dimensions-reference-table/
        // iPhone SE: 568 x 320
        // iphone 7: 667 × 375
        self.previewLayout(PreviewLayout.fixed(width: 320, height: 568))
    }
    
    @ViewBuilder func applyCustomStyle() -> some View {
        #if os(macOS)
        self.buttonStyle(LinkButtonStyle())
        #endif
    }
}
