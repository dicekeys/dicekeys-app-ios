//
//  SeedHardwareSecurityKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct SeedHardwareSecurityKey: View {
    var body: some View {
        Text("I'm afraid you can't do this on an iOS yet.")
    }
}

struct SeedHardwareSecurityKey_Previews: PreviewProvider {
    static var previews: some View {
        SeedHardwareSecurityKey()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
