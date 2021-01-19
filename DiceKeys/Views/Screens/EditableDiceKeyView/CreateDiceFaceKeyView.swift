//
//  DiceDemoView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 13/01/21.
//

import SwiftUI

/// CreateDiceFaceKeyView
struct TypeYourDiceKeyView: View {
    
    @StateObject var diceFaceManager: DiceFaceManager = DiceFaceManager()
    
    var body: some View {
        GeometryReader { (geo) in
            VStack(spacing: 12) {
                Text(diceFaceManager.displayMessage)
                
                CustomDiceFaceView(diceFaceManager: diceFaceManager)
                    .frame(width: geo.size.width, height: geo.size.height / 2, alignment: .topLeading)
                
                DiceKeyboardView(diceFaceManager: diceFaceManager)
                    .frame(width: geo.size.width, height: geo.size.height / 2, alignment: .center)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .padding()
        .navigationTitle("Type your Dicekey")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarDiceKeyStyle()
    }
}

struct CreateDiceFaceKeyView_Previews: PreviewProvider {
    static var previews: some View {
        TypeYourDiceKeyView()
    }
}
