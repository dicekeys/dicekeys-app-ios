//
//  NavigationBar.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/09.
//

import Foundation
import SwiftUI

private func getGradientImage(forBounds bounds: CGRect) -> UIImage? {
    let gradient = CAGradientLayer()

    gradient.frame = bounds
    gradient.colors = [UIColor.systemBlue.cgColor, UIColor.lighterBlue.cgColor]
    gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
    gradient.endPoint = CGPoint(x: 1.0, y: 1.0)

    UIGraphicsBeginImageContext(gradient.frame.size)
    defer {
        UIGraphicsEndImageContext()
    }
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    gradient.render(in: context)
    return UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
}

struct NavigationBarModifierDiceKeysStyle: ViewModifier {
    init() {
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
//        coloredAppearance.backgroundColor = .clear
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                GeometryReader { geometry in
                    if let image = getGradientImage(forBounds: CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.safeAreaInsets.top)) {
                        Image(uiImage: image)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    } else {
                        Color(.alexandrasBlue)
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                        Text("Uh oh")
                    }
                    Spacer()
                }
            }
        }
    }
}

extension View {
    func navigationBarDiceKeyStyle() -> some View {
        self.modifier(NavigationBarModifierDiceKeysStyle())
    }
}
