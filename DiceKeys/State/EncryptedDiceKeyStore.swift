//
//  EncryptedStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import Foundation
import LocalAuthentication
import Combine
import CryptoKit

/// A set of functions to simplify storing strings in the Apple KeyChain
/// such that only this app on this device can read them.
private class KeyChain {
    enum KeyChainError: Error {
        case notFound
        case osError(OSStatus)
    }
    
    class func deleteKey(id: String, throwIfFails: Bool = false) throws {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: id,
                     kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                     kSecUseDataProtectionKeychain: true,
        ] as [String: Any]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && throwIfFails {
            throw KeyChainError.osError((status))
        }
    }
    
    class func saveKey(id: String, key: Data) throws {
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: id,
                     kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                     kSecUseDataProtectionKeychain: true,
                     kSecValueData: key
        ] as [String: Any]

        try deleteKey(id: id)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeyChainError.osError((status))
        }
    }
    
    class func saveKey(id: String, key: String) throws {
        try saveKey(id: id, key: key.data(using: .utf8)!)
    }
    
    class func isPresentInKeyChain(id: String) -> Bool {
        // Seek a generic password with the given account.
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: id,
                     kSecUseDataProtectionKeychain: true
        ] as [String: Any]
        
        switch SecItemCopyMatching(query as CFDictionary, nil) {
        case errSecSuccess: return true
        default: return false
        }
    }


    class func loadKeyData(id: String) throws -> Data {
        // Seek a generic password with the given account.
        let query = [kSecClass: kSecClassGenericPassword,
                     kSecAttrAccount: id,
                     kSecUseDataProtectionKeychain: true,
                     kSecReturnData: true
        ] as [String: Any]

        // Find and cast the result as data.
        var item: CFTypeRef?
        
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { throw KeyChainError.notFound }
            return data
        case errSecItemNotFound: throw KeyChainError.notFound
        default: throw KeyChainError.osError(status)
        }
    }
    
    class func loadKeyString(id: String) throws -> String {
        return String(decoding: try loadKeyData(id: id), as: UTF8.self)
    }
}

/// A store for raw DiceKeys that represents them as password credentials
/// in the Apple KeyChain for use only by this app on this device.
class EncryptedDiceKeyStore {
    let defaultReason = "Unlock your DiceKey"

    class func getReason(forCenterFace centerFace: Face?) -> String {
        if let face = centerFace {
            return "Unlock DiceKey with \(face.letterAndDigit) in Center"
        }
        return defaultReason
    }

    class func authenticate (
        reason: String? = nil,
        _ onComplete: @escaping (_ wasAuthenticated: Result<Void, LAError>) -> Void
    ) {
        var error: NSError?
        let laContext = LAContext()
        guard laContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            onComplete(.failure(LAError(_nsError: error!)))
            return
        }
        laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ?? defaultReason ) { success, error in
            onComplete(success ? .success(()) : .failure(LAError(LAError.Code(rawValue: error!._code)!)))
        }
    }

    class func authenticate (
        reason: String?
    ) -> Future<Void, LAError> {
        return Future<Void, LAError> { promise in
            self.authenticate(reason: reason) { result in promise(result) }
        }
    }

    class func getDiceKey(fromKeyId keyId: String, centerFace: Face? = nil, _ onComplete: @escaping (Result<DiceKey, Error>) -> Void) {
        self.authenticate(reason: getReason(forCenterFace: centerFace)) { authResult in
            switch authResult {
            case .failure(let error): onComplete(.failure(error)); return
            case .success: break
            }
            do {
                let diceKeyInHRF = try KeyChain.loadKeyString(id: keyId) //  String(contentsOf: try Directories.getRawDiceKeyFileUrl(forKeyId: keyId), encoding: .utf8)
                let diceKey = try DiceKey.createFrom(humanReadableForm: diceKeyInHRF)
                onComplete(.success(diceKey))
            } catch {
                onComplete(.failure(error))
            }
            return
        }
    }

    class func delete(keyId: String) -> Result<Void, Error> {
        try! KeyChain.deleteKey(id: keyId)
        return .success(())
    }

    class func hasDiceKey(forKeyId keyId: String) -> Bool {
        KeyChain.isPresentInKeyChain(id: keyId)
    }

    class func getDiceKey(fromKeyId keyId: String) -> Future<DiceKey, Error> {
        return Future<DiceKey, Error> { promise in
            self.getDiceKey(fromKeyId: keyId) { result in promise(result) }
        }
    }

    class func put(diceKey: DiceKey, _ onComplete: @escaping (Result<String, Error>) -> Void) {
        do {
            let keyId = diceKey.id
            try KeyChain.saveKey(id: keyId, key: diceKey.toHumanReadableForm())
            onComplete(.success(keyId))
        } catch {
            onComplete(.failure(error))
        }
    }

    class func put(diceKey: DiceKey) throws -> Future<String, Error> {
        return Future<String, Error> { promise in
                self.put(diceKey: diceKey) { result in promise(result) }
        }
    }
}
