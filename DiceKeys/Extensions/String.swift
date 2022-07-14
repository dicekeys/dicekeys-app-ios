//
//  String.swift
//  DiceKeys (iOS)
//
//  Created by Angelos Veglektsis on 7/20/22.
//

import Foundation

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}

extension Optional where Wrapped == String {
  var isBlank: Bool {
    return self?.isBlank ?? true
  }
}

extension String {
  func trim() -> String {
      return self.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
