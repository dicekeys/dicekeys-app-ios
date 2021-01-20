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
    
    var displayMessage: String {
        if let face = editableDiceKeyState.faceSelected {
            if face.letter == nil {
                return "One Letter required"
            } else if face.digit == nil {
                return "One Digit required"
            } else {
                return "Selected: \(face.letter!.rawValue)\(face.digit!.rawValue), Orientation"
            }
        }
        return "Please select one square"
    }
    
    var body: some View {
        let geometryReader = GeometryReader { (geo) in
            VStack(spacing: 12) {
                Text(displayMessage)
                
                VStack {
                    EditableDiceKeyView(editableDiceKeyState: editableDiceKeyState)
                        .padding()
                }
                .frame(width: geo.size.width, height: geo.size.height / 2, alignment: .topLeading)
                .background(Color.blue)
                .cornerRadius(12)
                
                DiceKeyboardView(editableDiceKeyState: editableDiceKeyState)
                    .frame(width: geo.size.width, height: geo.size.height / 2, alignment: .center)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .padding()
        .navigationTitle("Type your Dicekey")
        #if os(iOS)
            return geometryReader
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarDiceKeyStyle()
        #else
            return geometryReader
        #endif
    }
}

struct CreateDiceFaceKeyView_Previews: PreviewProvider {
    static var previews: some View {
        TypeYourDiceKeyView()
    }
}
