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
    let content: (GeometryProxy) -> BodyContent
    
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
            self.content(geometry)
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

struct WithNavigationHeader_Previews: PreviewProvider {
    static var previews: some View {
        WithNavigationHeader(header: {
            Text("test")
        }) { geometry in
            Text("test")
        }
    }
}

