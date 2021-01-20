//
//  DiceKeyboardView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

private func getFaceOrientationImageName(_ orientation: FaceOrientationLetterTrbl) -> String {
    switch orientation {
    case .Top:
        return "chevron.up.circle.fill"
    case .Right:
        return "chevron.right.circle.fill"
    case .Bottom:
        return "chevron.down.circle.fill"
    case .Left:
        return "chevron.left.circle.fill"
    }
}

struct DiceKeyboardView: View {
    @ObservedObject var editableDiceKeyState: EditableDiceKeyState
    
    var body: some View {
        GeometryReader { (geo) in
            VStack(spacing: 12) {
                if let face = editableDiceKeyState.faceSelected {
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 4, content: {
                        Section {
                            ForEach(0...4, id: \.self) { (index) in
                                if FaceOrientationLettersTrbl.indices.contains(index) {
                                    Image(systemName: getFaceOrientationImageName(FaceOrientationLettersTrbl[index]))
                                        .onTapGesture {
                                            face.orientation = FaceOrientationLettersTrbl[index]
                                        }
                                } else {
                                    Image(systemName: "delete.right.fill")
                                        .onTapGesture {
                                            face.letter = nil
                                            face.digit = nil
                                            face.orientation = .Top
                                        }
                                }
                            }
                        }
                    })
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 4, content: {
                    if let face = editableDiceKeyState.faceSelected {
                        if face.letter == nil {
                            Section {
                                ForEach(FaceLetters, id: \.self) { faceLetter in
                                    Text(faceLetter.rawValue)
                                        .font(.system(size: 18))
                                        .frame(width: 40, height: 30)
                                        .border(Color.black, width: 1)
                                        .onTapGesture {
                                            face.letter = faceLetter
                                        }
                                }
                            }
                        } else if (face.digit != nil) {
                            Section {
                                ForEach(FaceDigits, id: \.self) { faceDigit in
                                    Text("\(faceDigit.rawValue)")
                                        .font(.system(size: 18))
                                        .frame(width: 40, height: 30)
                                        .border(Color.black, width: 1)
                                        .onTapGesture {
                                            face.digit = faceDigit
                                            editableDiceKeyState.moveNext()
                                    }
                                }
                            }
                        }
                    }
                })
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .animation(.linear(duration: 0.25))
        }
    }
}
