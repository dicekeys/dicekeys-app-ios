//
//  UIViewController.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/09.
//

import Foundation
import UIKit

extension UIViewController {

    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */

    var topbarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }

    var topbarWidth: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.width ?? 0.0) +
            (self.navigationController?.navigationBar.frame.width ?? 0.0)
    }
    
    var navigationBarSize: CGSize { CGSize(
        width: topbarWidth,
        height: topbarHeight
    ) }
}
