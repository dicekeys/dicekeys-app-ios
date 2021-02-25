//
//  DiceKeyMemoryStore.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation

enum MemoryStoreExpirationState {
    case empty
    case keysNeverExpire
    case countdownDeferred
    case countdownInProgress(whenExpiring: Date)
}

private let defaultExpirationPeriodInSeconds = 59 //  5 * 60

final class DiceKeyMemoryStore: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private(set) var singleton = DiceKeyMemoryStore()

    // the currentTime value should update whenever a timer is fired, and the timer
    // is sued when in the countdownInProgress state
    @Published private var currentTime: Date = Date() { didSet {
        if case let .countdownInProgress(whenExpiring: expirationTime) = self.memoryStoreExpirationState {
            if currentTime > expirationTime && keyCache.count > 0 {
                self.expireAllKeys()
            }
        }
    }}
    private var timer: Timer?
    func onTimerFired() {
        self.currentTime = Date()
        self.sendChangeEventOnMainThread()
    }
    private func clearTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }

    @Published private(set) var memoryStoreExpirationState: MemoryStoreExpirationState = .empty {
        didSet {
            if case .countdownInProgress = oldValue {
                self.clearTimer()
            }
            if case .countdownInProgress = self.memoryStoreExpirationState {
                self.currentTime = Date()
                self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    self.onTimerFired()
                }
                self.timer?.tolerance = 0.1
            }
            self.sendChangeEventOnMainThread()
        }
    }
    
    private var keyCache: [String: DiceKey] = [:]
    
    func expireKey(_ keyId: String) {
        keyCache.removeValue(forKey: keyId)
        self.sendChangeEventOnMainThread()
    }
    func expireKey(_ diceKey: DiceKey) {
        expireKey(diceKey.id)
    }
    func expireKey() {
        let foregroundDiceKeyId = self.foregroundDiceKeyId
        if foregroundDiceKeyId.count > 0 {
            expireKey(foregroundDiceKeyId)
        }
    }

    func expireAllKeys() {
        self.keyCache = [:]
        self.memoryStoreExpirationState = .empty
    }
    
    var allDiceKeys: [DiceKey] {
        keyCache.values.sorted{ $0.centerFace.humanReadableForm < $1.centerFace.humanReadableForm }
    }
    
    func contains(_ keyId: String) -> Bool {
        return self.keyCache[keyId] != nil
    }
    
    var isEmpty: Bool {
        if case .empty = self.memoryStoreExpirationState { return true } else { return false }
    }
    
    var isCountdownTimerRunning: Bool {
        if case .countdownInProgress = self.memoryStoreExpirationState { return true } else { return false }
    }

    var expirationTime: Date {
        if case let .countdownInProgress(whenExpiring: expirationTime) = self.memoryStoreExpirationState {
            return expirationTime
        } else {
            return Date.distantFuture
        }
    }

    func startExpirationCountdown(_ whenExpiring: Date = Date().addingTimeInterval(TimeInterval(defaultExpirationPeriodInSeconds))) {
        self.memoryStoreExpirationState = .countdownInProgress(whenExpiring: whenExpiring)
    }

    func deferExpirationCountdown() {
        self.memoryStoreExpirationState = .countdownDeferred
        self.sendChangeEventOnMainThread()
    }

    
    var isTimerOn: Bool {
        expirationTime != Date.distantFuture && expirationTime >= currentTime
    }
    
    var timeRemainingInFractionalSeconds: TimeInterval {
        return expirationTime.timeIntervalSince(currentTime)
    }
    
    var secondsRemaining: Int {
        Int(timeRemainingInFractionalSeconds ) % 60
    }
    
    var minutesRemaining: Int {
        (Int(timeRemainingInFractionalSeconds ) / 60) % 60
    }
    
    var formattedTimeRemaining: String {
         "\(minutesRemaining):\(String(format: "%02d", self.secondsRemaining))"
    }
    
    @Published var foregroundDiceKeyId: String = "" { didSet { self.sendChangeEventOnMainThread() } }
    
    var diceKeyLoaded: DiceKey? {
        keyCache[foregroundDiceKeyId] ?? nil
    }
    


    /// The app should always use the singleton and never use this constructor directly.
    /// It exists eexclusively for the purpose of allowing previews and tests to create
    /// different test memory store states.
    init(_ diceKeyForTestUseOnly: DiceKey? = nil) {
        if let diceKey = diceKeyForTestUseOnly {
            let keyId = diceKey.id
            self.keyCache[keyId] = diceKey
            self.foregroundDiceKeyId = keyId
        }
        super.init()
    }
    
    func setDiceKey(diceKey: DiceKey) {
        let keyId = diceKey.id
        self.keyCache[keyId] = diceKey
        self.foregroundDiceKeyId = keyId
        // Defer expiration whle we use this DiceKey
        self.memoryStoreExpirationState = .countdownDeferred
    }
    
    func clearForegroundDiceKey() {
        self.foregroundDiceKeyId = ""
        if case .countdownDeferred = self.memoryStoreExpirationState {
            self.startExpirationCountdown()
        }
    }
    
    private var cachedDiceKeyState: UnlockedDiceKeyState? = nil
    var diceKeyState: UnlockedDiceKeyState? {
        if (cachedDiceKeyState?.diceKey != self.diceKeyLoaded) {
            if let diceKey = diceKeyLoaded {
                cachedDiceKeyState = UnlockedDiceKeyState(diceKey: diceKey)
            } else {
                cachedDiceKeyState = nil
            }
        }
        return cachedDiceKeyState
    }
}
