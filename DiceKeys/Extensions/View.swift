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

    @ViewBuilder func hideIf(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
}
