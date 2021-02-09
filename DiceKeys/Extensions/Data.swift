//
//  Data.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation

fileprivate func isAsciiPrintable(_ byte: UInt8) -> Bool {
    return (byte >= 32 && byte <= 126) ||
        // tab
        byte == 9 ||
        // CR / LF
        byte == 10 || byte == 13
}

fileprivate func isAsciiPrintable(_ data: Data) -> Bool {
    data.allSatisfy(isAsciiPrintable)
}


extension Data {
    // a hex string encoding of the data (no prefix such as "0x".  Add it if you want it.)
    var asHexString: String {
        self.reduce("") {$0 + String(format: "%02x", $1)}
    }
    
    /// If the data passed contains only ASCII printable characters, return it as a string.
    /// Otherwise, return a the data in hex format.
    /// This allows us to display ASCII messages to the user in a format they can read,
    /// and to display some visual presentation of the data otherwise.
    var asReadableString : String {
        isAsciiPrintable(self) ?
            String(decoding: self, as: UTF8.self) :
            self.asHexString
    }

}
