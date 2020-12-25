//
//  UIWindow+Orientation.swift
//  DiceKeys
//
//  Created by Nikita Titov on 29.10.2020.
//

#if os(iOS)
import UIKit

extension UIWindow {
    static var orientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
}
#endif
