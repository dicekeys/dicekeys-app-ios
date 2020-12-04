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

private func hexString(_ iterator: Array<UInt8>.Iterator) -> String {
    return iterator.map { String(format: "%02x", $0) }.joined()
}

class Directories {
    private static func get(forRelativePath relativePath: String) throws -> URL {
        let appSupportDirUrl = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let directoryAtRelativePath = appSupportDirUrl.appendingPathComponent(relativePath)
        try FileManager.default.createDirectory(atPath: directoryAtRelativePath.path, withIntermediateDirectories: true, attributes: nil)
        return directoryAtRelativePath
    }

    private static func getRawDiceKeysDirectory() throws -> URL { try Directories.get(forRelativePath: "dicekeys/raw") }

    static func getPublicDiceKeysDirectory(forKeyId keyId: String) throws -> URL { try Directories.get(forRelativePath: "dicekeys/public/\(keyId)") }

    // Get a file URL from an area in the system not visible to user
    static func getRawDiceKeyFileUrl(forKeyId keyId: String) throws -> URL {
        return try getRawDiceKeysDirectory().appendingPathComponent(keyId).appendingPathExtension("dky")
    }
}

//class PublicKeysFiles {
//}

class EncryptedDiceKeyFileAccessor {
    private var laContext: LAContext

    private init() {
        laContext = LAContext()
    }

    static private(set) var instance = EncryptedDiceKeyFileAccessor()

    func authenticate (
        reason: String = "Authenticate to access your DiceKey",
        _ onComplete: @escaping (_ wasAuthenticated: Result<Void, LAError>) -> Void
    ) {
        var error: NSError?
        guard self.laContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            onComplete(.failure(LAError(_nsError: error!)))
            return
        }
        self.laContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
            onComplete(success ? .success(()) : .failure(LAError(LAError.Code(rawValue: error!._code)!)))
        }
    }

    func authenticate (
        reason: String = "Authenticate to access your DiceKey"
    ) -> Future<Void, LAError> {
        return Future<Void, LAError> { promise in
            self.authenticate(reason: reason) { result in promise(result) }
        }
    }

    func getDiceKey(fromKeyId keyId: String, _ onComplete: @escaping (Result<DiceKey, Error>) -> Void) {
        self.authenticate { authResult in
            switch authResult {
            case .failure(let error): onComplete(.failure(error)); return
            case .success: break
            }
            do {
                let diceKeyInHRF = try String(contentsOf: try Directories.getRawDiceKeyFileUrl(forKeyId: keyId), encoding: .utf8)
                let diceKey = try DiceKey.createFrom(humanReadableForm: diceKeyInHRF)
                onComplete(.success(diceKey))
            } catch {
                onComplete(.failure(error))
            }
            return
        }
    }

    func delete(keyId: String) -> Result<Void, Error> {
        do {
            try FileManager.default.removeItem(at: try Directories.getRawDiceKeyFileUrl(forKeyId: keyId))
            return .success(())
        } catch {
            return .failure(error)
            // Do nothing on error
        }
    }

    func hasDiceKey(forKeyId keyId: String) -> Bool {
        guard let fileUrl = try? Directories.getRawDiceKeyFileUrl(forKeyId: keyId) else { return false }
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }

    func getDiceKey(fromKeyId keyId: String) -> Future<DiceKey, Error> {
        return Future<DiceKey, Error> { promise in
            self.getDiceKey(fromKeyId: keyId) { result in promise(result) }
        }
    }

    func put(diceKey: DiceKey, _ onComplete: @escaping (Result<String, Error>) -> Void) {
        do {
            // Convert DiceKey to a file in human-readable form, UTF8
            let diceKeyInHRF = diceKey.toHumanReadableForm(includeOrientations: true)
            let data = diceKeyInHRF.data(using: .utf8)!
            // Create a file name by taking the first 64 bits of the SHA256 hash of
            // the canonical human-readable form
            let keyId = diceKey.id
            var fileUrl = try Directories.getRawDiceKeyFileUrl(forKeyId: keyId)
            // Write the data with the highest-level of security protection
            try data.write(to: fileUrl, options: .completeFileProtection)
            // Make sure the file is not allowed to be backed up to the cloud
            var resourceValueExcludeFromBackup = URLResourceValues()
            resourceValueExcludeFromBackup.isExcludedFromBackup = true
            try fileUrl.setResourceValues(resourceValueExcludeFromBackup)
            onComplete(.success(keyId))
        } catch {
            onComplete(.failure(error))
        }
    }

    func put(diceKey: DiceKey) throws -> Future<String, Error> {
        return Future<String, Error> { promise in
                self.put(diceKey: diceKey) { result in promise(result) }
        }
    }
}
