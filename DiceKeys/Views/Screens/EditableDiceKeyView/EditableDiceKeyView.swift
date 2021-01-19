//
//  CustomDiceFaceView.swift
//  DiceKeys
//
//  Created by Kevin Shah on 16/01/21.
//

import SwiftUI

/// DiceFaceManager
class DiceFaceManager: ObservableObject {
    
    @Published var arrDiceFaceModel: [DiceFaceModel] = []
    @Published var diceSelectedIndex: Int = 0
    
    var selectedDiceFaceModel: DiceFaceModel? {
        if arrDiceFaceModel.indices.contains(diceSelectedIndex) {
            return arrDiceFaceModel[diceSelectedIndex]
        }
        return nil
    }
    
    var displayMessage: String {
        if let model = self.selectedDiceFaceModel {
            if model.letter == nil {
                return "One Letter required"
            } else if model.digit == nil {
                return "One Digit required"
            } else {
                return "Selected: \(model.letter!.rawValue)\(model.digit!.rawValue), Orientation"
            }
        }
        return "Please select one square"
    }
    
    func selectNextDiceIfNeeded() {
        if let selectedModel = self.selectedDiceFaceModel {
            if let index = arrDiceFaceModel.firstIndex(where: { (model) -> Bool in
                return !model.isDiceFaceModelValid
            }) {
                self.diceSelectedIndex = index
            } else {
                if let currentIndex = self.arrDiceFaceModel.firstIndex(where: { (model) -> Bool in
                    return model.id == selectedModel.id
                }) {
                    let nextIndex: Int = currentIndex + 1
                    if self.arrDiceFaceModel.indices.contains(nextIndex) {
                        self.diceSelectedIndex = nextIndex
                    }
                }
            }
        }
    }
}

/// DiceFaceModel
class DiceFaceModel: ObservableObject {
    
    var id: String = UUID().uuidString
    
    @Published var letter: FaceLetter?
    @Published var digit: FaceDigit?
    @Published var orientation: FaceOrientationLetterTrbl = .Top
    
    var isDiceFaceModelValid: Bool {
        return (letter != nil) && (digit != nil)
    }
    
    var face: Face? {
        if let faceLetter = self.letter, let faceDigit = self.digit {
            return Face(letter: faceLetter, digit: faceDigit, orientationAsLowercaseLetterTrbl: self.orientation)
        }
        return nil
    }
    
    init(_ letter: FaceLetter, digit: FaceDigit) {
        self.letter = letter
        self.digit = digit
    }
    
    init() {
        self.letter = nil
        self.digit = nil
    }
}

struct EditableDiceKeyView: View {
    
    @ObservedObject var diceFaceManager: DiceFaceManager
    
    var body: some View {
        GeometryReader { (geo) in
            let width: CGFloat = geo.size.width / 5
            let height: CGFloat = geo.size.height / 5
            LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 4, content: {
                let arr = Array(zip(diceFaceManager.arrDiceFaceModel.indices, diceFaceManager.arrDiceFaceModel))
                ForEach(arr, id: \.0) { (index, faceModel) in
                    self.diceView(index, faceModel: faceModel, size: CGSize(width: width - 4, height: height))
                        .cornerRadius(12)
                        .onTapGesture {
                            diceFaceManager.diceSelectedIndex = index
                            diceFaceManager.objectWillChange.send()
                        }
                }
            })
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear(perform: {
            for _ in 0...24 {
                self.diceFaceManager.arrDiceFaceModel.append(DiceFaceModel())
            }
            self.diceFaceManager.diceSelectedIndex = 0
        })
    }
    
    func diceView(_ index: Int, faceModel: DiceFaceModel, size: CGSize) -> AnyView {
        let diceColor: Color = (self.diceFaceManager.diceSelectedIndex == index) ? .green : .white
        if let model = faceModel.face, faceModel.isDiceFaceModelValid {
            let dieFaceView = DieFaceView(face: model, dieSize: size.width, faceSurfaceColor: diceColor)
                .frame(width: size.width, height: size.height)
            return AnyView(dieFaceView)
        } else {
            let vStack = VStack {
                
            }
            .frame(width: size.width, height: size.height)
            .background(diceColor)
            return AnyView(vStack)
        }
    }
}
