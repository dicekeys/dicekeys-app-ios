//
//  Data.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation

extension Data {
    var hexString: String {
        self.reduce("") {$0 + String(format: "%02x", $1)}
    }
}
