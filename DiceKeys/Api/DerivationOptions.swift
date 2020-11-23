//
//  File.swift
//  
//
//  Created by Stuart Schechter on 2020/11/12.
//

import Foundation

enum HashFunction: String, Codable {
    case BLAKE2b, Argon2id
}

enum DerivationOptionsType: String, Codable {
    case Password, Secret, SigningKey, SymmetricKey, UnsealingKey
}

enum WordListName: String, Codable {
    case EN_512_words_5_chars_max_ed_4_20200917,
         EN_1024_words_6_chars_max_ed_4_20200917
}

struct DerivationOptions: AuthenticationRequirements, Codable {
    var type: DerivationOptionsType?
    var allow: [WebBasedApplicationIdentity]?
    var requireAuthenticationHandshake: Bool?
    var allowAndroidPrefixes: [String]?

    /**
   * A string that may be added by the DiceKeys app to help users remember which
   * seed (DiceKey) they used to derive a key or secret.
   *
   * e.g. `My DiceKey labeled "Personal Accounts".`
   */
    var seedHint: String?

  /**
   * A specific seed hint consisting of the letters at the four corners of
   * the DiceKey, in clockwise order from wherever the user initially
   * scanned as the top-left corner.
   *
   * The array must be a string consisting of four uppercase characters
   */
    var cornerLetters: String?

  /**
   * The DiceKeys app will want to get a user's consent before deriving a
   * secret on behalf of an app.
   *
   * When a user approves a set of DerivationOptions, this field
   * allows us to record that the options were, at least at one time, approved
   * by the holder of this DiceKey.
   *
   * Set this field to empty (two double quotes, ""), call DerivationOptions.derivePrimarySecret
   * with the seed (DiceKey) and these derivation options.  Take that primary secret,
   * turn it into url-safe base64, and then re-run derivePrimarySecret with that
   * base64 encoding as the seed. Insert the base64 encoding of the first 128 bits
   * into this field.  (If the derivation options derive fewer than 128 bits, use
   * whatever bits are available.)
   */
    var proofOfPriorDerivation: String?

  /**
   * Unless this value is explicitly set to _true_, the DiceKeys may prevent
   * to obtain a raw derived [[SymmetricKey]],
   * UnsealingKey, or
   * SigningKey.
   * Clients may retrieve a derived SealingKey,
   * or SignatureVerificationKey even if this value
   * is not set or set to false.
   *
   * Even if this value is set to true, requests for keys are not permitted unless
   * the client would be authorized to perform cryptographic operations on those keys.
   * In other words, access is forbidden if the [restrictions] field is set and the
   * specified [Restrictions] are not met.
   */
    var clientMayRetrieveKey: Bool?

  /**
   * When using a DiceKey as a seed, the default seed string will be a 75-character
   * string consisting of triples for each die in canonical order:
   *
   *   1 The uppercase letter on the die
   *   2 The digit on the die
   *   3 The orientation relative to the top of the square
   *
   * If  `excludeOrientationOfFaces` is set to `true` set to true,
   * the orientation character (the third member of each triple) will be
   * set to "?" before the canonical form is determined
   * (the choice of the top left corner that results in the human readable
   * form earliest in the sort order) and "?" will be the third character
   * in each triple.
   *
   * This option exists because orientations may be harder for users to copy correctly
   * than letters and digits are. With this option on, should a user choose to manually
   * copy the contents of a DiceKey and make an error in copying an orientation, that
   * error will not prevent them from re-deriving the specified key or secret.

    */
    var excludeOrientationOfFaces: Bool?
    var hashFunction: HashFunction?
    var hashFunctionMemoryLimitInBytes: Int64?
    var hashFunctionMemoryPasses: Int64?
    var lengthInBytes: Int32?
    var lengthInWords: Int32?
    var lengthInBits: Int32?
    var wordList: WordListName?

    static func fromJson(_ json: Data) throws -> DerivationOptions {
        return try JSONDecoder().decode(DerivationOptions.self, from: json)
    }

    static func fromJson(_ json: String?) throws -> DerivationOptions? {
        guard let nonNilJson = json else {
            return DerivationOptions()
        }
        if nonNilJson == "" {
            return DerivationOptions()
        }
        return try fromJson(nonNilJson.data(using: .utf8)!)
    }

    func toJson() throws -> String {
        return try String(decoding: JSONEncoder().encode(self), as: UTF8.self)
    }
}
