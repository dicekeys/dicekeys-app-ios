//
//  DiceDemoView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 13/01/21.
//

import SwiftUI

/// TypeYourDiceKeyView
struct TypeYourDiceKeyView: View {
    @StateObject var editableDiceKeyState: EditableDiceKeyState = EditableDiceKeyState()
        
    var body: some View {
        let view = VStack(alignment: .center) {
            Spacer()
            DiceKeyView(
                partialFaces: editableDiceKeyState.faces,
                highlightIndexes: Set([editableDiceKeyState.faceSelectedIndex]),
                onFacePressed: { faceIndex in editableDiceKeyState.faceSelectedIndex = faceIndex })
            Spacer()
            DiceKeyboardView(editableDiceKeyState: editableDiceKeyState)
            Spacer()
            Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                Text("Done")
            }).showIf(editableDiceKeyState.diceKey != nil)
            Spacer()
        }
        .padding()
        .navigationTitle("Type your Dicekey")
        #if os(iOS)
            return view
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarDiceKeyStyle()
        #else
            return view
        #endif
    }
}

struct CreateDiceFaceKeyView_Previews: PreviewProvider {
    static var previews: some View {
        TypeYourDiceKeyView()
    }
}
