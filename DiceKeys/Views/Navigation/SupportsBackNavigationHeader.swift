//
//  SupportsBackNavigationHeader.swift
//  DiceKeys (iOS)
//
//  Created by Stuart Schechter on 2021/01/28.
//

import Foundation
import SwiftUI

protocol SupportsBackNavigationHeader {

    var goBack: () -> Void { get }
    
}

struct WithNavigationHeader<HeaderContent: View, BodyContent: View>: View {
    let header: () -> HeaderContent
    let content: () -> BodyContent
    
    var body: some View {
        GeometryReader { geometry in
        let vStack = VStack(alignment: .leading, spacing: 0) {
            // NavigationBar
            VStack(alignment: .leading, spacing: 0) {
                #if os(iOS)
                Color.alexandrasBlue.frame(width: geometry.size.width, height: geometry.safeAreaInsets.top)
                #endif
                VStack {
                self.header()
                }
//                HStack(alignment: .top, spacing: 0, content: {
//                    Button( action: { goBack }, content: { Text("Back") } )
//                })
            }.background(Color.alexandrasBlue)//.background(
//                        if let image = getGradientImage(forBounds: CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.safeAreaInsets.top)) {
//                            Image(uiImage: image)
//                            .frame(height: geometry.safeAreaInsets.top)
//                            .edgesIgnoringSafeArea(.top)
//                        } else {
//                            Color.alexandrasBlue
//                            .frame(height: geometry.safeAreaInsets.top)
//                            .edgesIgnoringSafeArea(.top)
//                        }
//            )
            //Removing this. Let the content decide if it needs Spacer()
//            Spacer()
            self.content()
        }
        #if os(macOS)
        vStack.edgesIgnoringSafeArea(.leading)
            .edgesIgnoringSafeArea(.bottom)
            .edgesIgnoringSafeArea(.trailing)
        #else
        vStack.edgesIgnoringSafeArea(.all)
        #endif
            
        }
    }
}
