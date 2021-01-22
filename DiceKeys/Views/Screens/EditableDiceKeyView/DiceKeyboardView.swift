//
//  DiceKeyboardView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

struct DiceKeyboardView: View {
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState

    var orientationAndNavigationKeys: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 7), spacing: 4, content: {
            Text(" ").font(.system(size: 128, design: .monospaced)).scaledToFit().minimumScaleFactor(0.01)
                .background( Image(systemName: "rotate.left").resizable().aspectRatio(contentMode: .fit) )
                .onTapGesture { editableDiceKeyState.rotateLeft() }
            Text(" ").font(.system(size: 128, design: .monospaced)).scaledToFit().minimumScaleFactor(0.01)
                .background( Image(systemName: "rotate.right").resizable().aspectRatio(contentMode: .fit) )
                .onTapGesture { editableDiceKeyState.rotateRight() }
            Text(" ").font(.system(size: 128, design: .monospaced)).scaledToFit().minimumScaleFactor(0.01)
                .background( Image(systemName: "delete.right.fill").resizable().aspectRatio(contentMode: .fit) )
                .onTapGesture { editableDiceKeyState.backspace() }
        })
    }
    
    var letterKeys: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 8), spacing: 4, content: {
            ForEach(FaceLetters, id: \.self) { faceLetter in
                Text(faceLetter.rawValue)
                    .font(.system(size: 128, design: .monospaced)).scaledToFit().minimumScaleFactor(0.01)
                    .lineLimit(1)
                    .border(Color.gray, width: 1)
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture { editableDiceKeyState.enter(letter: faceLetter) }
            }
        })
    }
    
    var digitKeys: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 4, content: {
            ForEach(FaceDigits, id: \.self) { faceDigit in
                Text("\(faceDigit.rawValue)")
                    .font(.system(size: 128, design: .monospaced)).scaledToFit().minimumScaleFactor(0.01)
                    .lineLimit(1)
                    .border(Color.gray, width: 1)
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture { editableDiceKeyState.enter(digit: faceDigit) }
            }
        })
    }
    
    var showLetterKeys: Bool {
        editableDiceKeyState.faceSelected.letter == nil || editableDiceKeyState.faceSelected.digit != nil
    }

    var body: some View {
        #if os(macOS)
        Text("To rotate the current face, use either < >, - +, or CTRL arrow (right and left arrows).")
            .onReceive(NotificationCenter.default.publisher(for: NotificationCenter.keyEquivalentPressed)) { (object) in
                if let key = object.object as? KeyboardCommandsModel {
                    editableDiceKeyState.keyPressed(keyboardCommandsModel: key)
                }
            }
        #else
        VStack {
            orientationAndNavigationKeys
            Spacer(minLength: 12)
            ZStack(alignment: .top) {
                letterKeys.showIf(showLetterKeys)
                digitKeys.hideIf(showLetterKeys)
            }
        }
//            .animation(.linear(duration: 0.25))
        #endif
    }
}
