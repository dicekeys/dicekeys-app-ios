//
//  Mnemonic.swift
//
//  See BIP39 specification for more info:
//  https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
//
//  Created by Liu Pengpeng on 2019/10/10.
//  Edited by Angelos Veglektsis on 7/12/22.
//
import Foundation
import CryptoKit

public class Mnemonic {
    public enum Error: Swift.Error {
        case invalidMnemonic
        case invalidEntropy
    }
    
    // Entropy -> Mnemonic
    public static func toMnemonic(_ bytes: [UInt8], wordlist: [String] = Wordlist.english) throws -> [String] {
        let entropyBits = String(bytes.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        let checksumBits = Mnemonic.deriveChecksumBits(bytes)
        let bits = entropyBits + checksumBits
        
        var phrase = [String]()
        for i in 0..<(bits.count / 11) {
            let wi = Int(bits[bits.index(bits.startIndex, offsetBy: i * 11)..<bits.index(bits.startIndex, offsetBy: (i + 1) * 11)], radix: 2)!
            phrase.append(String(wordlist[wi]))
        }
        return phrase
    }
    
    public static func deriveChecksumBits(_ bytes: [UInt8]) -> String {
        let ENT = bytes.count * 8;
        let CS = ENT / 32
        
        let hash = SHA256.hash(data: bytes)
        let hashbits = String(hash.flatMap { ("00000000" + String($0, radix:2)).suffix(8) })
        return String(hashbits.prefix(CS))
    }
}
