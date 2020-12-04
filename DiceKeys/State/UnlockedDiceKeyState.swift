//
//  DiceKeyState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/01.
//
import Foundation
import Combine
import SwiftUI

class KnownDiceKeyState: ObservableObjectUpdatingOnAllChangesToUserDefaults, Identifiable {
    enum FieldName: String {
        case centerFace
//        case nickname
    }

    let keyId: String

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

    @Published fileprivate var protectedCacheOfIsDiceKeyStored: Bool?

    var isDiceKeyStored: Bool {
        get {
            if self.protectedCacheOfIsDiceKeyStored == nil {
                self.protectedCacheOfIsDiceKeyStored = EncryptedDiceKeyFileAccessor.instance.hasDiceKey(forKeyId: keyId)
            }
            return self.protectedCacheOfIsDiceKeyStored ?? EncryptedDiceKeyFileAccessor.instance.hasDiceKey(forKeyId: keyId)
        }
    }

    static func fieldKey(_ fieldName: FieldName, _ keyId: String) -> String {
        "keyId: '\(keyId)', field: '\(fieldName.rawValue)'"
    }

    init(_ forKeyId: String) {
        self.keyId = forKeyId
//        self._nickname = UserDefault(DiceKeyState.fieldKey(.nickname, keyId), "")
        self._centerFaceInHumanReadableForm = UserDefault(UnlockedDiceKeyState.fieldKey(.centerFace, keyId), "?")
        super.init()
    }
}

final class UnlockedDiceKeyState: KnownDiceKeyState {
    let diceKey: DiceKey

    override var centerFace: Face {
        get {
            diceKey.centerFace
        }
    }

    override var isCenterFaceStored: Bool {
        get { super.isCenterFaceStored }
        set {
            if newValue {
                self.centerFaceInHumanReadableForm = diceKey.faces[12].humanReadableForm
            } else {
                self.centerFaceInHumanReadableForm = ""
            }
        }
    }

    override var isDiceKeyStored: Bool {
        get { super.isDiceKeyStored }
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
            } else {
                _  = EncryptedDiceKeyFileAccessor.instance.delete(keyId: keyId)
                self.protectedCacheOfIsDiceKeyStored = false
            }
        }
    }

    init(_ forDiceKey: DiceKey) {
        self.diceKey = forDiceKey
        super.init(forDiceKey.id)
        // Force default nickname to be written to stable store
        // self.nickname = "\(nickname)"
        if centerFaceInHumanReadableForm == "?" {
            // Set the default value for this field if no value has ever been set
            self.isCenterFaceStored = true
        }
    }
}
