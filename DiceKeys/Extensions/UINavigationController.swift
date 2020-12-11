//
//  UINavigationController.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/03.
//

import Foundation
import SwiftUI
import UIKit

extension UINavigationController {
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

    func setBackground() {
        if let image = getGradientImage(forBounds: navigationBar.bounds) {
//        if let image = getGradientImage(forBounds: CGRect(origin: CGPoint(x: 0, y: 0), size: navigationBarSize)) {
            navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
            navigationBar.setBackgroundImage(image, for: UIBarMetrics.compact)
            navigationBar.standardAppearance.backgroundImage = image
            navigationBar.titleTextAttributes = [.foregroundColor: UIColor.DiceKeysNavigationForeground]
            navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.DiceKeysNavigationForeground]
            navigationBar.tintColor = UIColor.DiceKeysNavigationForeground
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setBackground()
    }
}
