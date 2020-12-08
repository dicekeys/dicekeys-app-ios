//
//  RoundedTextButton.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/04.
//

import SwiftUI

struct RoundedTextButton: View {
    let text: String
    let action: () -> Void

    init(_ text: String, _ action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    var body: some View {
        Button(action: action, label: {
            Text(text)
            .font(.title2)
            .padding(.vertical, 5)
            .padding(.horizontal, 20)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.alexandrasBlue)
            )
        })
    }
}

struct RoundedTextButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundedTextButton("Hello", { print("Hello") })
    }
}
