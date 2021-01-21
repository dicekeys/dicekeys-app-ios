//
//  DiceKeyboardView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

extension FaceOrientationLetterTrbl {
    var right: FaceOrientationLetterTrbl {
        switch(self) {
        case .Top: return .Right
        case .Right: return .Bottom
        case .Bottom: return .Left
        case .Left: return .Top
        }
    }

    var left: FaceOrientationLetterTrbl {
        switch(self) {
        case .Top: return .Left
        case .Right: return .Top
        case .Bottom: return .Right
        case .Left: return .Bottom
        }
    }

}

struct DiceKeyboardView: View {
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState

    var orientationAndNavigationKeys: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 4, content: {
            Section {
                Image(systemName: "rotate.left")
                .onTapGesture {
                    if let orientation = editableDiceKeyState.faceSelected?.orientation {
                        editableDiceKeyState.faceSelected?.orientation = orientation.left
                    }
                }
                Image(systemName: "rotate.right")
                .onTapGesture {
                    if let orientation = editableDiceKeyState.faceSelected?.orientation {
                        editableDiceKeyState.faceSelected?.orientation = orientation.right
                    }
                }
                Image(systemName: "delete.right.fill")
                .onTapGesture {
                    if editableDiceKeyState.faceSelectedIndex > 0 && editableDiceKeyState.faceSelected?.letter == nil && editableDiceKeyState.faceSelected?.digit == nil {
                        editableDiceKeyState.movePrev()
                    }
                    editableDiceKeyState.faceSelected?.letter = nil
                    editableDiceKeyState.faceSelected?.digit = nil
                    editableDiceKeyState.faceSelected?.orientation = .Top
                }
            }
        })
    }
    
    var letterKeys: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 4, content: {
            ForEach(FaceLetters, id: \.self) { faceLetter in
                Text(faceLetter.rawValue)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 30)
                    .border(Color.black, width: 1)
                    .onTapGesture {
                        if (editableDiceKeyState.faceSelected?.letter != nil) {
                            editableDiceKeyState.moveNext()
                        }
                        editableDiceKeyState.faceSelected?.letter = faceLetter
                    }
            }
        })
    }
    
    var digitKeys: some View {
        LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 4, content: {
            ForEach(FaceDigits, id: \.self) { faceDigit in
                Text("\(faceDigit.rawValue)")
                    .font(.system(size: 18))
                    .frame(width: 40, height: 30)
                    .border(Color.black, width: 1)
                    .onTapGesture {
                        editableDiceKeyState.faceSelected?.digit = faceDigit
                }
            }
        })
    }

    var body: some View {
        GeometryReader { (geo) in
            VStack(spacing: 12) {
                if (editableDiceKeyState.faceSelected?.letter != nil) {
                   orientationAndNavigationKeys
                }
                if (editableDiceKeyState.faceSelected?.letter == nil || editableDiceKeyState.faceSelected?.digit != nil) {
                    letterKeys
                } else if (editableDiceKeyState.faceSelected?.digit == nil) {
                    digitKeys
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .animation(.linear(duration: 0.25))
        }
    }
}
