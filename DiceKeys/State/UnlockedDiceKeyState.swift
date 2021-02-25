//
//  DiceKeyState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/01.
//
import Foundation
import Combine
import SwiftUI

protocol DiceKeyMetadata {
    var keyId: String { get }
    
    var nickname: String { get }
    
    var centerFace: Face? { get }
    
    var isCenterFaceStored: Bool { get }
    
    var isDiceKeyStored: Bool { get }
}

extension DiceKeyMetadata {
    var nickname: String {
        guard let centerFace = self.centerFace else { return "Unknown DiceKey" }
        return "DiceKey with \(centerFace.letter.rawValue)\(centerFace.digit.rawValue) in center"
    }
    
    var isCenterFaceStored: Bool {
        get {
            centerFace != nil
        }
    }

    var isDiceKeyStored: Bool {
        get {
            return EncryptedDiceKeyStore.hasDiceKey(forKeyId: keyId)
        }
    }
}

class StoredEncryptedDiceKeyMetadata: ObservableObjectUpdatingOnAllChangesToUserDefaults, DiceKeyMetadata, Identifiable {
    let keyId: String

    enum FieldName: String {
        case centerFace
    }

    // To comply with Identifiable protocol
    var id: String { keyId }

    @UserDefault var centerFaceInHumanReadableForm: String

    var nickname: String {
        guard let centerFace = self.centerFace else { return "Unknown DiceKey" }
        return "DiceKey with \(centerFace.letter.rawValue)\(centerFace.digit.rawValue) in center"
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
        self._centerFaceInHumanReadableForm = UserDefault(StoredEncryptedDiceKeyMetadata.fieldKey(.centerFace, keyId), "?")
        super.init()
    }
    
    private static var known: [String: StoredEncryptedDiceKeyMetadata] = [:]

    static func forKeyId(_ forKeyId: String) -> StoredEncryptedDiceKeyMetadata {
        guard let existingRecord = known[forKeyId] else {
            let result = StoredEncryptedDiceKeyMetadata(forKeyId)
            known[forKeyId] = result
            return result
        }
        return existingRecord
    }

}

final class UnlockedDiceKeyState: ObservableObjectUpdatingOnAllChangesToUserDefaults, DiceKeyMetadata {
    @Published var diceKey: DiceKey {
        didSet { self.sendChangeEventOnMainThread() }
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
        get { StoredEncryptedDiceKeyMetadata.forKeyId(keyId).isCenterFaceStored }
        set {
            if newValue{
                StoredEncryptedDiceKeyMetadata.forKeyId(keyId).centerFaceInHumanReadableForm = diceKey.faces[12].humanReadableForm
            } else {
                StoredEncryptedDiceKeyMetadata.forKeyId(keyId).centerFaceInHumanReadableForm = ""
            }
        }
    }

    @Published fileprivate var protectedCacheOfIsDiceKeyStored: Bool?

    var isDiceKeyStored: Bool {
        get {
            return EncryptedDiceKeyStore.hasDiceKey(forKeyId: keyId)
        }
        set {
            // Currently we are storing the center face IFF we are storing the DiceKey
            isCenterFaceStored = newValue
            if newValue {
                EncryptedDiceKeyStore.put(diceKey: diceKey) { result in
                    switch result {
                    case .failure(let error): print(error)
                    case .success:
                        self.protectedCacheOfIsDiceKeyStored = true
                    }
                }
                KnownDiceKeysStore.singleton.addKnownDiceKey(keyId: diceKey.id)
            } else {
                _  = EncryptedDiceKeyStore.delete(keyId: keyId)
                self.protectedCacheOfIsDiceKeyStored = false
                KnownDiceKeysStore.singleton.removeKnownDiceKey(keyId: diceKey.id)
            }
            self.sendChangeEventOnMainThread()
        }
    }

    var isDiceKeyStoredBinding: Binding<Bool> { Binding<Bool>(
        get: { self.isDiceKeyStored }, set: { self.isDiceKeyStored = $0 })
    }

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
