//
//  DiceKeyboardView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

private struct KeyboardKey<Content: View>: View {
    let size: CGSize
    let action: () -> Void
    let label: () -> Content

    var body: some View {
        Button(action: action, label: {
            label()
//            .aspectRatio(2, contentMode: .fit)
            .frame(width: size.width * 0.95, height: size.height * 0.95)
            .clipped()
            .background(Color.gray)
            .padding(.horizontal, size.width * 0.025)
            .padding(.vertical, size.height * 0.025)
        })
    }
}

private struct CharacterKey: View {
    let size: CGSize
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState
    var char: Character

    var body: some View {
        KeyboardKey(size: size, action: { editableDiceKeyState.keyDown(char: char) } , label: {
            Text("\(String(char))")
                .font(.system(size: 256, design: .monospaced))
                .foregroundColor(.white)
                .scaledToFit()
                .minimumScaleFactor(0.01)
                .lineLimit(1)
        })
    }
}

private struct ImageKey: View {
    let size: CGSize
    let action: () -> Void
    var image: Image

    var body: some View {
        KeyboardKey(size: size, action: action, label: {
            image
            .resizable()
            .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
        })
    }
}


struct DiceKeyboardView: View {
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState

    private let fractionalSpaceBetween: CGFloat = 0.1
    private let columns: Int = 9
    private let rows: Int = 4

    @State private var bounds: CGSize = CGSize(width: 1, height: 1)
    var width: CGFloat { bounds.width / CGFloat(columns) }
    var height: CGFloat { width / 2 }
    var padding: CGFloat { fractionalSpaceBetween * width / 2 }
    var buttonWidth: CGFloat { width - 2 * padding }
    var buttonHeight: CGFloat { height - 2 * padding }
    var buttonSize: CGSize { CGSize(width: buttonWidth, height: buttonHeight) }
    var left: CGFloat { ( (1 - CGFloat(columns)) / 2 ) * width }
    var top: CGFloat { ( (1 - CGFloat(rows)) / 2 ) * height }
    func buttonOffset(x: Int, y: Int) -> CGSize {
        CGSize(
            width: left + CGFloat(x) * width,
            height: top + CGFloat(y) * height
        )
    }
    
    var showLetterKeys: Bool {
        editableDiceKeyState.faceSelected.letter == nil || editableDiceKeyState.faceSelected.digit != nil
    }

    var body: some View {
        #if os(macOS)
        Text("To rotate the current face, use either < >, - +, or CTRL arrow (right and left arrows).")
            .onReceive(NotificationCenter.default.publisher(for: NotificationCenter.keyEquivalentPressed)) { (object) in
                if let id = object.object as? String {
                    editableDiceKeyState.keyPressed(id: id)
                }
            }
        #else
        CalculateBounds(bounds: $bounds) {
            ZStack(alignment: .center) {
                ImageKey(size: buttonSize, action: {editableDiceKeyState.rotateLeft()}, image: Image(systemName: "rotate.left"))
                    .offset(buttonOffset(x: 0, y: 0))
                ImageKey(size: buttonSize, action: {editableDiceKeyState.rotateRight()}, image: Image(systemName: "rotate.right"))
                    .offset(buttonOffset(x: 1, y: 0))
                ImageKey(size: buttonSize, action: {editableDiceKeyState.backspace()}, image: Image(systemName: "delete.right.fill"))
                    .offset(buttonOffset(x: columns - 1, y: 0))
                ForEach(0..<FaceLetters.count) { faceLetterIndex in
                    CharacterKey(size: buttonSize, editableDiceKeyState: editableDiceKeyState, char: FaceLetters[faceLetterIndex].rawValue.first!)
                    .offset(buttonOffset(x: (faceLetterIndex % columns), y: 1 + faceLetterIndex / columns))
                    .showIf(showLetterKeys)
                }
                ForEach(0..<FaceDigits.count) { faceDigitIndex in
                    CharacterKey(size: buttonSize, editableDiceKeyState: editableDiceKeyState, char: FaceDigits[faceDigitIndex].rawValue.first!)
                    .offset(buttonOffset(x: faceDigitIndex + 2, y: 2))
                    .hideIf(showLetterKeys)
                }
            }.frame(width: width * CGFloat(columns), height: height * CGFloat(rows))
        }.aspectRatio(CGFloat(columns) / CGFloat(rows), contentMode: .fit)
        #endif
    }
}

struct DiceKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        DiceKeyboardView(editableDiceKeyState: EditableDiceKeyState())
    }
}
