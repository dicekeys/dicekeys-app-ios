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
}
