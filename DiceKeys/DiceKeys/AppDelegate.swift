//
//  AppDelegate.swift
//  DiceKeys
//
//  Created by Nikita Titov on 27.10.2020.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // Test
        do {
            // Initialize wrapper
            let wrapper = DKDiceKeyImageProcessorWrapper.create()!

            // Load test image from bundle
            let image = UIImage(named: "test.png")!

            let w = image.bitmapWidth
            let h = image.bitmapHeight

            let data = image.rgba()

            // Test API
            // processRGBAImageAndRenderOverlay
//            var overlay = wrapper.processRGBAImageAndRenderOverlay(w, height: h, bytes: data)
//            overlay.withUnsafeMutableBytes { rawBufferPointer in
//                let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
//                let overlayImage = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)
//
//                imageView.image = overlayImage
//            }

            var augmented = wrapper.processAndAugmentRGBAImage(w, height: h, bytes: data)
            augmented.withUnsafeMutableBytes { rawBufferPointer in
                let ptr: UnsafeMutablePointer<UInt8> = rawBufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                let image = ImageHelper.convertBitmapRGBA8(toUIImage: ptr, withWidth: w, withHeight: h)

                print(image)
            }

            //        print(wrapper.processRGBAImage(w, height: h, bytes: data))
            //        print(wrapper.processAndAugmentRGBAImage(w, height: h, bytes: data))
            //        print(wrapper.readJson())
            //        print(wrapper.isFinished())
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
