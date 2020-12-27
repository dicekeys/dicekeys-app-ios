//
//  Color.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/25.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static var highlighter: Color { Color("highlighter") }
//    static let highlighter: Color = Color(CGColor(red: 1, green: 1, blue: 0, alpha: 0.5))
//    static let alexandrasBlue: Color = Color(hex: "5576C5")
    static var alexandrasBlue: Color { Color("alexandrasBlue") }
//    static let alexandrasBlueLighter: Color = Color(hex: "607BCA")
    static var alexandrasBlueLighter: Color { Color("alexandrasBlueLighter") }
    static var DiceKeysNavigationForeground: Color { Color("navigationBarForeground") }
    static var warningBackground: Color { Color("warningBackground") }

//    static let warningBackground = Color(hex: "E0585B")
//    static var diceBox = Color(hex: "050350")
    static var diceBox: Color { Color("diceBox") }
//    static var diceBoxDieSlot = Color(hex: "040240")
    static var diceBoxDieSlot: Color { Color("diceBoxDieSlot") }

//    static var formHeadingBackground = Color(hex: "080808")
//    static var formHeadingForeground = Color(hex: "FFFFFF")
//    static var formContentBackground = Color(hex: "F8F8F8")
    static var formHeadingBackground: Color { Color("formHeadingBackground") }
    static var formHeadingForeground: Color { Color("formHeadingForeground") }
    static var formContentBackground: Color { Color("formContentBackground") }
    static var formInstructions: Color { Color("formInstructions") }

    
    static var funnelBackground: Color { Color("funnelBackground") }
//    static let funnelBackground: Color = {
//        let rgba1 = Color.alexandrasBlue.cgColor!.components!
//        let rgba2 = UIColor.systemBackground.cgColor.components!
//        let red: Double = Double(rgba1[0] + rgba2[0]) / 2
//        let green: Double = Double(rgba1[1] + rgba2[1]) / 2
//        let blue: Double = Double(rgba1[2] + rgba2[2]) / 2
//        return Color(RGBColorSpace.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
//    }()
}

extension UIColor {
//    static let DiceKeysNavigationForeground = UIColor.white
//    static let alexandrasBlue = UIColor(Color.alexandrasBlue)

    static let lighterBlue: UIColor = {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor.systemBlue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: red, green: green, blue: blue, alpha: alpha * 0.50)
    }()
}
