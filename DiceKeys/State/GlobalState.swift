//
//  DefaultsStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2020/11/30.
//

import Foundation
import Combine

final class GlobalState: ObservableObject {
    static private(set) var instance = GlobalState()

    enum Fields: String {
        case neverAskUserToSave
    }

    @UserDefault(Fields.neverAskUserToSave.rawValue, false) var neverAskUserToSave: Bool

    let objectWillChange = ObservableObjectPublisher()
    private var notificationSubscription: AnyCancellable?

    @UserDefault("DerivablesJson", "") private var derivablesJson: String

    var derivables: [Derivable] {
        get {
            return derivablesJson == "" ? PasswordDerivable :
                (try? Derivable.listFromJson(derivablesJson)) ?? PasswordDerivable
        } set {
            if let derivablesJson = try? Derivable.listToJson(newValue) {
                self.derivablesJson = derivablesJson
            }
        }
    }

    init() {
        notificationSubscription = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { _ in
            self.objectWillChange.send()
        }
    }
}
