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
    
    var selectedDiceFaceModel: DiceFaceModel? {
        return arrDiceFaceModel.first { (model) -> Bool in
            return model.isSelected
        }
    }
    
    var displayMessage: String {
        if let model = self.selectedDiceFaceModel {
            if model.letter == .none {
                return "One Letter required"
            } else if model.digit == ._none {
                return "One Digit required"
            } else {
                return "Selected: \(model.letter.rawValue)\(model.digit.rawValue), Orientation"
            }
        }
        return "Please select one square"
    }
    
    func selectNextDiceIfNeeded() {
        if let selectedModel = self.selectedDiceFaceModel {
            selectedModel.isSelected = false
            if let model = arrDiceFaceModel.first(where: { (model) -> Bool in
                return !model.isDiceFaceModelValid
            }) {
                model.isSelected = true
            } else {
                if let currentIndex = self.arrDiceFaceModel.firstIndex(where: { (model) -> Bool in
                    return model.id == selectedModel.id
                }) {
                    let nextIndex: Int = currentIndex + 1
                    if self.arrDiceFaceModel.indices.contains(nextIndex) {
                        self.arrDiceFaceModel[nextIndex].isSelected = true
                    }
                }
            }
        }
    }
}

/// DiceFaceModel
class DiceFaceModel: ObservableObject {
    
    var id: String = UUID().uuidString
    
    @Published var letter: FaceLetter
    @Published var digit: FaceDigit
    @Published var orientation: FaceOrientationLetterTrbl = .Top
    
    @Published var isSelected: Bool = false
    
    var isDiceFaceModelValid: Bool {
        return (letter != .none) && (digit != ._none)
    }
    
    var faceModel: Face {
        return Face(letter: self.letter, digit: self.digit, orientationAsLowercaseLetterTrbl: self.orientation)
    }
    
    init(_ letter: FaceLetter, digit: FaceDigit) {
        self.letter = letter
        self.digit = digit
    }
    
    init() {
        self.letter = .none
        self.digit = ._none
    }
}

struct CustomDiceFaceView: View {
    
    @ObservedObject var diceFaceManager: DiceFaceManager
    
    var body: some View {
        GeometryReader { (geo) in
            let width: CGFloat = geo.size.width / 5
            let height: CGFloat = geo.size.height / 5
            LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 4, content: {
                ForEach(diceFaceManager.arrDiceFaceModel, id: \.id) { faceModel in
                    if faceModel.isDiceFaceModelValid {
                        DieFaceView(face: faceModel.faceModel, dieSize: width - 4, faceSurfaceColor: faceModel.isSelected ? .green : .white)
                            .cornerRadius(12)
                            .onTapGesture {
                                for model in diceFaceManager.arrDiceFaceModel {
                                    model.isSelected = false
                                }
                                faceModel.isSelected = true
                                diceFaceManager.objectWillChange.send()
                            }
                    } else {
                        BlankView(blankViewModel: BlankViewModel(faceModel.isSelected))
                            .frame(width: width, height: height, alignment: .center)
                            .onTapGesture {
                                for model in diceFaceManager.arrDiceFaceModel {
                                    model.isSelected = false
                                }
                                faceModel.isSelected = !faceModel.isSelected
                                diceFaceManager.objectWillChange.send()
                            }
                    }
                }
            })
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear(perform: {
            for _ in 0...24 {
                self.diceFaceManager.arrDiceFaceModel.append(DiceFaceModel())
            }
            self.diceFaceManager.arrDiceFaceModel.first?.isSelected = true
        })
    }
}
