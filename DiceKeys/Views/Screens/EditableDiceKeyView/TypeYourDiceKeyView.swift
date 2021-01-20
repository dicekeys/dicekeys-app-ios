//
//  DiceDemoView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 13/01/21.
//

import SwiftUI

/// TypeYourDiceKeyView
struct TypeYourDiceKeyView: View {
    
    @StateObject var diceFaceManager: DiceFaceManager = DiceFaceManager()
    
    var body: some View {
        let geometryReader = GeometryReader { (geo) in
            VStack(spacing: 12) {
                Text(diceFaceManager.displayMessage)
                
                VStack {
                    EditableDiceKeyView(diceFaceManager: diceFaceManager)
                        .padding()
                }
                .frame(width: geo.size.width, height: geo.size.height / 2, alignment: .topLeading)
                .background(Color.blue)
                .cornerRadius(12)
                
                DiceKeyboardView(diceFaceManager: diceFaceManager)
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
