//
//  ObservableObjectUpdatingOnAllChangesToUserDefaults.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/12/01.
//

import Foundation
import Combine

class ObservableObjectUpdatingOnAllChangesToUserDefaults: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private var notificationSubscription: AnyCancellable?

    init() {
        notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
            self.sendChangeEventOnMainThread()
        }
    }
    
    func sendChangeEventOnMainThread() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
}
