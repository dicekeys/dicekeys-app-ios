//
//  AppView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/23.
//

import SwiftUI

class AppState: ObservableObject {
    @Published var diceKey: DiceKey?
}

struct App_Previews: PreviewProvider {
    static var previews: some View {
        AppMainView()
    }
}

@main
struct AppView: App {
    var body: some Scene {
        WindowGroup {
            AppMainView()
                .onOpenURL { url in
                    // FIXME -- handle deep linking API requests here
                    print("\(url.absoluteString)")
                }
//                .onContinueUserActivity("put-some-activityhere", perform: { userActivity in
//                })
        }
    }
}
