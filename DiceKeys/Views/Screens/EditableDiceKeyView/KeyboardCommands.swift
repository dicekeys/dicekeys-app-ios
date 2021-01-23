//
//  KeyboardCommands.swift
//  DiceKeys
//
//  Created by Kevin Shah on 22/01/21.
//

import SwiftUI

/// It will be appear at status bar of macOS, as the name of Inputs.
struct KeyboardCommands: Commands {
    
    let idToKeyEquivalent: [String: KeyEquivalent] = {
        var idToKeyEquivalentBuilder: [String: KeyEquivalent] = [
            "delete": .delete,
            "upArrow": .upArrow,
            "downArrow": .downArrow,
            "rightArrow": .rightArrow,
            "leftArrow": .leftArrow,
            ",": KeyEquivalent(","),
            ".": KeyEquivalent("."),
            "<": KeyEquivalent("<"),
            ">": KeyEquivalent(">"),
            "+": KeyEquivalent("+"),
            "=": KeyEquivalent("="),
            "-": KeyEquivalent("-")
        ]
        for letter in FaceLetters {
            idToKeyEquivalentBuilder[letter.rawValue] = KeyEquivalent(letter.rawValue.first!)
            /// For lower keys
            idToKeyEquivalentBuilder[letter.rawValue.lowercased()] = KeyEquivalent(letter.rawValue.lowercased().first!)
        }
        for digit in FaceDigits { idToKeyEquivalentBuilder[digit.rawValue] = KeyEquivalent(digit.rawValue.first!) }
        return idToKeyEquivalentBuilder
    }()
    
    var keyEquivalentCompletion: ((String) -> ())?
    
    var body: some Commands {
        CommandMenu("Inputs") {
            ForEach(idToKeyEquivalent.sorted(by: { $0.key > $1.key }), id: \.key) { (key, value) in
                Button {
                    keyEquivalentCompletion?(key)
                } label: {
                    Text("")
                }
                .keyboardShortcut(value, modifiers: EventModifiers())
            }
        }
    }
}

extension NotificationCenter {
    static let keyEquivalentPressed: Notification.Name = Notification.Name("keyEquivalentPressed")
}
