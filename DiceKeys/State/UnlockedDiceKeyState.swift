//
//  DiceKeyState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/01.
//
import Foundation
import Combine
import SwiftUI

protocol DiceKeyState {
    var keyId: String { get }
    
    var nickname: String { get }
    
    var centerFace: Face? { get }
    
    var isCenterFaceStored: Bool { get }
    
    var isDiceKeySaved: Bool { get }
}

extension DiceKeyState {
    var nickname: String {
        guard let centerFace = self.centerFace else { return "Unknown DiceKey" }
        return "DiceKey with \(centerFace.letter.rawValue)\(centerFace.digit.rawValue) in center"
    }
    
    var isCenterFaceStored: Bool {
        get {
            centerFace != nil
        }
    }

    var isDiceKeySaved: Bool {
        get {
            return EncryptedDiceKeyFileAccessor.instance.hasDiceKey(forKeyId: keyId)
        }
    }
}

class KnownDiceKeyState: ObservableObjectUpdatingOnAllChangesToUserDefaults, DiceKeyState, Identifiable {
    let keyId: String

    enum FieldName: String {
        case centerFace
//        case nickname
    }

    // To comply with Identifiable protocol
    var id: String { keyId }

//    @UserDefault var nickname: String
    @UserDefault var centerFaceInHumanReadableForm: String

    //    @UserDefault var whatToStoreRaw: String?

    var nickname: String {
        guard let centerFace = self.centerFace else { return "Unknown DiceKey" }
        return "DiceKey with \(centerFace.letter.rawValue)\(centerFace.digit.rawValue) in center."
    }

    var centerFace: Face? {
        get {
            centerFaceInHumanReadableForm.count < 3 ? nil : try? Face(fromHumanReadableForm: centerFaceInHumanReadableForm)
        }
    }

    var isCenterFaceStored: Bool {
        get {
            centerFace != nil
        }
    }


    static func fieldKey(_ fieldName: FieldName, _ keyId: String) -> String {
        "keyId: '\(keyId)', field: '\(fieldName.rawValue)'"
    }

    private init(_ forKeyId: String) {
        self.keyId = forKeyId
        self._centerFaceInHumanReadableForm = UserDefault(KnownDiceKeyState.fieldKey(.centerFace, keyId), "?")
        super.init()
    }
    
    private static var known: [String: KnownDiceKeyState] = [:]

    static func forKeyId(_ forKeyId: String) -> KnownDiceKeyState {
        guard let existingRecord = known[forKeyId] else {
            let result = KnownDiceKeyState(forKeyId)
            known[forKeyId] = result
            return result
        }
        return existingRecord
    }

}

final class UnlockedDiceKeyState: ObservableObjectUpdatingOnAllChangesToUserDefaults, DiceKeyState {
    @Published var diceKey: DiceKey {
        didSet { objectWillChange.send() }
    }

    var keyId: String {
        return diceKey.id
    }

    var centerFace: Face? {
        get {
            diceKey.centerFace
        }
    }
    
    var id: String {
        return keyId
    }

    var isCenterFaceStored: Bool {
        get { KnownDiceKeyState.forKeyId(keyId).isCenterFaceStored }
        set {
            if newValue{
                KnownDiceKeyState.forKeyId(keyId).centerFaceInHumanReadableForm = diceKey.faces[12].humanReadableForm
            } else {
                KnownDiceKeyState.forKeyId(keyId).centerFaceInHumanReadableForm = ""
            }
        }
    }

    @Published fileprivate var protectedCacheOfIsDiceKeyStored: Bool?

    var isDiceKeySaved: Bool {
        get {
            return EncryptedDiceKeyFileAccessor.instance.hasDiceKey(forKeyId: keyId)
        }
        set {
            // Currently we are storing the center face IFF we are storing the DiceKey
            isCenterFaceStored = newValue
            if newValue {
                EncryptedDiceKeyFileAccessor.instance.put(diceKey: diceKey) { result in
                    switch result {
                    case .failure(let error): print(error)
                    case .success:
                        self.protectedCacheOfIsDiceKeyStored = true
                    }
                }
                GlobalState.instance.addKnownDiceKey(keyId: diceKey.id)
            } else {
                _  = EncryptedDiceKeyFileAccessor.instance.delete(keyId: keyId)
                self.protectedCacheOfIsDiceKeyStored = false
                GlobalState.instance.removeKnownDiceKey(keyId: diceKey.id)
            }
            self.objectWillChange.send()
        }
    }

    var isDiceKeyStoredBinding: Binding<Bool> { Binding<Bool>(
        get: { self.isDiceKeySaved }, set: { self.isDiceKeySaved = $0 })
    }

//    private init(_ forDiceKey: DiceKey) {
//        self.diceKey = forDiceKey
//        super.init(forDiceKey.id)
//    }
    init(diceKey: DiceKey) {
        self.diceKey = diceKey
    }

    private static var known: [String: UnlockedDiceKeyState] = [:]

    static func forDiceKey(_ diceKey: DiceKey) -> UnlockedDiceKeyState {
        guard let existingRecord = known[diceKey.id] else {
            let result = UnlockedDiceKeyState(diceKey: diceKey)
            known[diceKey.id] = result
            return result
        }
        return existingRecord
    }
    static func forget(diceKey: DiceKey) {
        UnlockedDiceKeyState.known.removeValue(forKey: diceKey.id)
    }
}
