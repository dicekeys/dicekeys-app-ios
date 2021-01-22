//
//  KeyboardCommands.swift
//  DiceKeys
//
//  Created by Kevin Shah on 22/01/21.
//

import SwiftUI

struct KeyboardCommandsModel: Identifiable {
    var id: String
    var key: KeyEquivalent
}

struct KeyboardCommands: Commands {
    
    let arrKeyboardCommandsModel: [KeyboardCommandsModel] = {
        return FaceLetters.map { (letter) -> KeyboardCommandsModel in
            return KeyboardCommandsModel(id: letter.rawValue, key: KeyEquivalent(letter.rawValue.first!))
        } + FaceLetters.map { (letter) -> KeyboardCommandsModel in
            /// For lower keys
            return KeyboardCommandsModel(id: letter.rawValue.lowercased(), key: KeyEquivalent(letter.rawValue.lowercased().first!))
        } + FaceDigits.map({ (digit) -> KeyboardCommandsModel in
            return KeyboardCommandsModel(id: digit.rawValue, key: KeyEquivalent(digit.rawValue.first!))
        }) + [KeyboardCommandsModel(id: "delete", key: .delete),
                KeyboardCommandsModel(id: "upArrow", key: .upArrow),
                KeyboardCommandsModel(id: "downArrow", key: .downArrow),
                KeyboardCommandsModel(id: "rightArrow", key: .rightArrow),
                KeyboardCommandsModel(id: "leftArrow", key: .leftArrow),
                KeyboardCommandsModel(id: ",", key: KeyEquivalent(",")),
                KeyboardCommandsModel(id: ".", key: KeyEquivalent(".")),
                KeyboardCommandsModel(id: "<", key: KeyEquivalent("<")),
                KeyboardCommandsModel(id: ">", key: KeyEquivalent(">")),
                KeyboardCommandsModel(id: "+", key: KeyEquivalent("+")),
                KeyboardCommandsModel(id: "=", key: KeyEquivalent("=")),
                KeyboardCommandsModel(id: "-", key: KeyEquivalent("-"))
            ]
    }()
    
    var keyEquivalentCompletion: ((KeyboardCommandsModel) -> ())?
    
    var body: some Commands {
        CommandMenu("") {
            ForEach(arrKeyboardCommandsModel, id: \.id) { (keyboardCommandsModel) in
                Button {
                    keyEquivalentCompletion?(keyboardCommandsModel)
                } label: {
                    Text("")
                }
                .keyboardShortcut(keyboardCommandsModel.key, modifiers: EventModifiers())
            }
        }
    }
}

extension NotificationCenter {
    static let keyEquivalentPressed: Notification.Name = Notification.Name("keyEquivalentPressed")
}
