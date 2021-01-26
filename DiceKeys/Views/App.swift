//
//  AppView.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/23.
//

import SwiftUI
import CoreData

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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppMainView()
                .onOpenURL { url in
                // FIXME -- handle deep linking API requests here
                print("\(url.absoluteString)")
            }
        }.onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                print("active")
            case .inactive:
                print("inactive")
            case .background:
                print("background")
            default:
                print(phase)
            }
        }.commands {
            KeyboardCommands { (keyboardCommandsModel) in
                NotificationCenter.default.post(name: NotificationCenter.keyEquivalentPressed, object: keyboardCommandsModel)
            }
        }
    }
}
