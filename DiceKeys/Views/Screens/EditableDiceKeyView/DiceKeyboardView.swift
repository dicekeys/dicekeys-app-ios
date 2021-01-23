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
        })
    }
}

struct DiceKeyboardView: View {
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState

    var letterKeys: some View {
        GeometryReader { geometry in
        let size = CGSize(width: geometry.size.width / 10, height: geometry.size.width / 20)
        LazyVGrid(columns: Array(repeating: GridItem(), count: 8), content: {
//        HStack {
//            EmptyView()
//            EmptyView()
//            EmptyView()
//            EmptyView()
            ImageKey(size: size, action: {editableDiceKeyState.rotateLeft()}, image: Image(systemName: "rotate.left"))
            ImageKey(size: size, action: {editableDiceKeyState.rotateRight()}, image: Image(systemName: "rotate.right"))
            ImageKey(size: size, action: {editableDiceKeyState.backspace()}, image: Image(systemName: "delete.right.fill"))
//            EmptyView()
            ForEach(FaceLetters, id: \.self) { faceLetter in
                CharacterKey(size: size, editableDiceKeyState: editableDiceKeyState, char: faceLetter.rawValue.first!)
            }
        })
        }//.aspectRatio(8 /* columns */ / 4 /* rows */, contentMode: .fit)
        .background(Color.green)
    }
    
    var digitKeys: some View {
        GeometryReader { geometry in
            let size = CGSize(width: geometry.size.width / 10, height: geometry.size.height / 5)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(geometry.size.width / 10), alignment: .center), count: 8), spacing: geometry.size.width / 100, content: {
            EmptyView()
            EmptyView()
            EmptyView()
            EmptyView()
            ImageKey(size: size, action: {editableDiceKeyState.rotateLeft()}, image: Image(systemName: "rotate.left"))
            ImageKey(size: size, action: {editableDiceKeyState.rotateRight()}, image: Image(systemName: "rotate.right"))
            ImageKey(size: size, action: {editableDiceKeyState.backspace()}, image: Image(systemName: "delete.right.fill"))
            EmptyView()

            ForEach(FaceDigits, id: \.self) { faceDigit in
                CharacterKey(size: size, editableDiceKeyState: editableDiceKeyState, char: faceDigit.rawValue.first!)
            }
        })
        }.aspectRatio(8 /* columns */ / 4 /* rows */, contentMode: .fit)
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
        VStack {
            ZStack(alignment: .top) {
                letterKeys.showIf(showLetterKeys)
                // digitKeys.hideIf(showLetterKeys)
            }
        }//.aspectRatio(8 /* columns */ / 4 /* rows */, contentMode: .fit)
//            .animation(.linear(duration: 0.25))
        #endif
    }
}
