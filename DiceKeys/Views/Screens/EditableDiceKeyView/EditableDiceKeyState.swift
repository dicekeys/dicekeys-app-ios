//
//  EditableDiceKeyState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/01/22.
//

import SwiftUI
import Foundation

class EditableDiceKeyState: ObservableObject {
    
    @Published var faces: [PartialFace]
    @Published var faceSelectedIndex: Int = 0  { didSet { objectWillChange.send() } }
    
    init() {
        faces = (0...24).map { PartialFace(index: $0) }
    }
    
    var diceKey: DiceKey? {
        guard (faces.allSatisfy { $0.isDiceFaceModelValid }) else {
            return nil
        }
        return DiceKey(faces.map { $0.face! })
    }

    var faceSelected: PartialFace {
        get { faces[faceSelectedIndex] }
        set { if faceSelectedIndex >= 0 && faceSelectedIndex < 25 { faces[faceSelectedIndex] = newValue } }
    }
    
    private var letter: FaceLetter? {
        get { faceSelected.letter }
        set { faceSelected.letter = newValue }
    }
    
    private var digit: FaceDigit? {
        get { faceSelected.digit }
        set { faceSelected.digit = newValue }
    }

    private var orientation: FaceOrientationLetterTrbl {
        get { faceSelected.orientation }
        set { faceSelected.orientation = newValue }
    }
    
    var nextEmptyDieIndex: Int? {
        faces.first { !$0.isDiceFaceModelValid }?.index
    }
    
    func moveNext() {
        faceSelectedIndex = min(24, faceSelectedIndex + 1)
    }
    
    func movePrev() {
        faceSelectedIndex = max(0, faceSelectedIndex - 1)
    }
    
    func moveDown() {
        faceSelectedIndex = (faceSelectedIndex + 5) % 25
    }

    func moveUp() {
        faceSelectedIndex = (faceSelectedIndex + 20) % 25
    }
    
    func rotateLeft() {
        faceSelected.orientation = faceSelected.orientation.left
    }
    
    func rotateRight() {
        faceSelected.orientation = faceSelected.orientation.left
    }
    
    func enter(letter: FaceLetter) {
        if self.letter != nil && digit != nil && faceSelectedIndex < 24 {
            // This die is complete so we'll assume the user wants to enter the letter
            // for the next die
            moveNext()
        }
        self.letter = letter
    }
    
    func enter(digit: FaceDigit) {
        if self.letter != nil && self.digit != nil && faceSelectedIndex < 24 {
            // This die is complete so we'll assume the user wants to enter the letter
            // for the next die
            moveNext()
        }
        self.digit = digit
    }
    
    func keyPressed(id: String) {
        switch id {
        case "<", ",", "-":
            self.rotateLeft()
        case ">", ".", "+", "=":
            self.rotateRight()
        case "delete":
            self.backspace()
        case "upArrow":
            self.moveUp()
        case "downArrow":
            self.moveDown()
        case "rightArrow":
            self.moveNext()
        case "leftArrow":
            self.movePrev()
        default:
            let keyId = id.uppercased()
            if let letter = FaceLetter(rawValue: keyId) {
                self.enter(letter: letter)
            } else if let digit = FaceDigit(rawValue: keyId) {
                self.enter(digit: digit)
            }
        }
    }
    
    func delete() {
        letter = nil
        digit = nil
        orientation = .Top
    }
    
    func backspace() {
        if faceSelectedIndex > 0 && letter == nil && digit == nil {
            movePrev()
        }
        delete()
    }
    
    func keyDown(char: Character) {
        if let letterKey = FaceLetter.init(rawValue: String(char)) {
            enter(letter: letterKey)
        } else if let digitKey = FaceDigit.init(rawValue: String(char)) {
            enter(digit: digitKey)
        }
    }
}
