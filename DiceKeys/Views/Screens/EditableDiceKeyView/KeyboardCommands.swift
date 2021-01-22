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
        var arr: [KeyboardCommandsModel] = []
        for letter in FaceLetters {
            let model = KeyboardCommandsModel(id: letter.rawValue, key: KeyEquivalent(letter.rawValue.first!))
            arr.append(model)
            
            let model1 = KeyboardCommandsModel(id: letter.rawValue.lowercased(), key: KeyEquivalent(letter.rawValue.lowercased().first!))
            arr.append(model1)
        }
        for digit in FaceDigits {
            let model = KeyboardCommandsModel(id: digit.rawValue, key: KeyEquivalent(digit.rawValue.first!))
            arr.append(model)
        }
        arr.append(KeyboardCommandsModel(id: "delete", key: .delete))
        arr.append(KeyboardCommandsModel(id: "upArrow", key: .upArrow))
        arr.append(KeyboardCommandsModel(id: "downArrow", key: .downArrow))
        arr.append(KeyboardCommandsModel(id: "rightArrow", key: .rightArrow))
        arr.append(KeyboardCommandsModel(id: "leftArrow", key: .leftArrow))
        
        arr.append(KeyboardCommandsModel(id: ",Key", key: KeyEquivalent(",")))
        arr.append(KeyboardCommandsModel(id: ".Key", key: KeyEquivalent(".")))
        arr.append(KeyboardCommandsModel(id: "<Arrow", key: KeyEquivalent("<")))
        arr.append(KeyboardCommandsModel(id: ">Arrow", key: KeyEquivalent(">")))
        arr.append(KeyboardCommandsModel(id: "+Key", key: KeyEquivalent("+")))
        arr.append(KeyboardCommandsModel(id: "=Key", key: KeyEquivalent("=")))
        arr.append(KeyboardCommandsModel(id: "-Key", key: KeyEquivalent("-")))
        
        return arr
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
