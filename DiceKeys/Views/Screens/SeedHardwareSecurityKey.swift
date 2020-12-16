//
//  SeedHardwareSecurityKey.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/28.
//

import SwiftUI

struct SeedHardwareSecurityKey: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Apple prevents apps on iPhones and iPads from writing to USB devices.").font(.title)
            
            Text("To seed a SoloKey, you will need to use this app on a Mac, Android device, or PC.").font(.title).padding(.top, 10)
        }
    }
}

struct SeedHardwareSecurityKey_Previews: PreviewProvider {
    static var previews: some View {
        SeedHardwareSecurityKey()
            .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    }
}
