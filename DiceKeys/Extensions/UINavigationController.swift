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
    private func getImageFrom(gradientLayer: CAGradientLayer) -> UIImage? {
        var gradientImage: UIImage?
        UIGraphicsBeginImageContext(gradientLayer.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            gradientImage = UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        }
        UIGraphicsEndImageContext()
        return gradientImage
    }

    func setBackground() {
        let gradient = CAGradientLayer()

        var bounds = navigationBar.bounds
        bounds.size.height += UIApplication.shared.statusBarFrame.size.height
        gradient.frame = bounds
        let lighterBlue: UIColor = {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            UIColor.systemBlue.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return UIColor(red: red, green: green, blue: blue, alpha: alpha * 0.25)
        }()
//        let blue = UIColor(red: UIColor.systemBlue.ciColor.red, green: UIColor.systemBlue.ciColor.green, blue: UIColor.systemBlue.ciColor.blue, alpha: 1)
        gradient.colors = [UIColor.systemBlue.cgColor, lighterBlue.cgColor]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)

        // navigationBar.backgroundColor = .systemBlue
        if let image = getImageFrom(gradientLayer: gradient) {
            navigationBar.setBackgroundImage(image, for: UIBarMetrics.default)
        }

        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBar.tintColor = UIColor.white
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.setBackground()
    }
}
