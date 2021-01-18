//
//  DiceKeyboardView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

struct DiceKeyboardView: View {
    
    @ObservedObject var diceFaceManager: DiceFaceManager
    
    var body: some View {
        GeometryReader { (geo) in
            VStack(spacing: 12) {
                if let model = diceFaceManager.selectedDiceFaceModel, model.isDiceFaceModelValid {
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 4, content: {
                        Section {
                            ForEach(0...4, id: \.self) { (index) in
                                if FaceOrientationLettersTrbl.indices.contains(index) {
                                    Image(systemName: FaceOrientationLettersTrbl[index].imageName)
                                        .onTapGesture {
                                            diceFaceManager.selectedDiceFaceModel?.orientation = FaceOrientationLettersTrbl[index]
                                            diceFaceManager.objectWillChange.send()
                                        }
                                } else {
                                    Image(systemName: "delete.right.fill")
                                        .onTapGesture {
                                            diceFaceManager.selectedDiceFaceModel?.letter = .none
                                            diceFaceManager.selectedDiceFaceModel?.digit = ._none
                                            diceFaceManager.objectWillChange.send()
                                        }
                                }
                            }
                        }
                    })
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 4, content: {
                    if let model = diceFaceManager.selectedDiceFaceModel, model.letter != .none {
                        Section {
                            ForEach(FaceDigits, id: \.self) { (faceDigit) in
                                Text("\(faceDigit.rawValue)")
                                    .font(.system(size: 18))
                                    .frame(width: 40, height: 30)
                                    .border(Color.black, width: 1)
                                    .onTapGesture {
                                        self.diceFaceManager.selectedDiceFaceModel?.digit = faceDigit
                                        self.diceFaceManager.selectNextDiceIfNeeded()
                                        self.diceFaceManager.objectWillChange.send()
                                    }
                            }
                        }
                    }
                    
                    Section {
                        ForEach(FaceLetters, id: \.self) { (faceLetter) in
                            Text(faceLetter.rawValue)
                                .font(.system(size: 18))
                                .frame(width: 40, height: 30)
                                .border(Color.black, width: 1)
                                .onTapGesture {
                                    diceFaceManager.selectedDiceFaceModel?.letter = faceLetter
                                    diceFaceManager.objectWillChange.send()
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
