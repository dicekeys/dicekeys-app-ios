//
//  PartialFace.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/01/20.
//

import Foundation

//class PartialFace: ObservableObject, Identifiable {
//    @Published var letter: FaceLetter? { didSet { objectWillChange.send() } }
//    @Published var digit: FaceDigit? { didSet { objectWillChange.send() } }
//    @Published var orientation: FaceOrientationLetterTrbl = .Top { didSet { objectWillChange.send() } }
struct PartialFace: Identifiable {
    var letter: FaceLetter?
    var digit: FaceDigit?
    var orientation: FaceOrientationLetterTrbl = .Top

    let index: Int
    var id: String { String(describing: index) }

    var isDiceFaceModelValid: Bool {
        return (letter != nil) && (digit != nil)
    }
    
    var face: Face? {
        if let faceLetter = self.letter, let faceDigit = self.digit {
            return Face(letter: faceLetter, digit: faceDigit, orientationAsLowercaseLetterTrbl: self.orientation)
        }
        return nil
    }
    
    init(_ face: Face, index: Int? = nil) {
        self.letter = face.letter
        self.digit = face.digit
        self.orientation = face.orientationAsLowercaseLetterTrbl
        self.index = index ?? 0
    }
    
    init(letter: FaceLetter? = nil, digit: FaceDigit? = nil, orientation: FaceOrientationLetterTrbl = FaceOrientationLetterTrbl.Top, index: Int? = nil) {
        self.letter = letter
        self.digit = digit
        self.index = index ?? 0
    }
}
