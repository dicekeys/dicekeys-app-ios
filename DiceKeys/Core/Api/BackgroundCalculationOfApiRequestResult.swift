//
//  BackgroundCalculationOfApiRequestResult.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation
import Combine
import CryptoKit

enum BackgroundCalculationError: Error {
    case inProgress
}

/// The calculated result of an API request, which runs in the background
/// and is cached so that a request never causes more than one calculation.
class BackgroundCalculationOfApiRequestResult: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    @Published var ready: Bool = false
    @Published var result: Result<SuccessResponse,Error> = .failure(BackgroundCalculationError.inProgress)
    private var onResultCallbacks: [(Result<SuccessResponse, Error>) throws -> Void] = []
    
    private func setSuccess(_ resultIfSuccess: SuccessResponse) {
        self.result = .success(resultIfSuccess)
        self.ready = true
        self.sendChangeEventOnMainThread()
    }
    
    private func setError(_ error: Error) {
        self.result = .failure(error)
        self.ready = true
        self.sendChangeEventOnMainThread()
    }
    
    private func callCallbacks(result: Result<SuccessResponse, Error>) {
        self.result = result
        for callback in onResultCallbacks {
            try? callback(result)
        }
    }
    
    private func onResult(_ callback: @escaping (Result<SuccessResponse, Error>) throws -> Void) {
        if case let .failure(error) = result, case BackgroundCalculationError.inProgress = error {
            // The calculation is ongoing. Defer the callback until th result is ready
            onResultCallbacks.append(callback)
        } else {
            // The result is ready so call the callback immediately.
            try? callback(result)
        }
    }
    
    static var cache: [String: BackgroundCalculationOfApiRequestResult] = [:]
    
    private init(request: ApiRequest, seedString: String) {
        super.init()
        execute(request: request, seedString: seedString)
    }
    
    private func execute(request: ApiRequest, seedString: String) {
        DispatchQueue.global(qos: .background).async {
            do {
                let result = try request.execute(seedString: seedString)
                DispatchQueue.main.async {
                    self.setSuccess(result)
                }
            } catch {
                DispatchQueue.main.async {
                    self.setError(error)
                }
            }
        }
    }
    
    static func get(request: ApiRequest, seedString: String, callback: @escaping (Result<SuccessResponse, Error>) throws -> Void) {
        let cacheKeyPreimage: String = request.id + seedString
        let cacheKey = SHA256.hash(data: cacheKeyPreimage.data(using: .utf8)!).description
        if let cachedResult = cache[cacheKey] {
            cachedResult.onResult(callback)
        } else {
            let result = BackgroundCalculationOfApiRequestResult(request: request, seedString: seedString)
            cache[cacheKey] = result
            result.onResult(callback)
        }
    }
    
    static func get(request: ApiRequest, seedString: String) -> BackgroundCalculationOfApiRequestResult {
        let cacheKeyPreimage: String = request.id + seedString
        let cacheKey = SHA256.hash(data: cacheKeyPreimage.data(using: .utf8)!).description
        if let cachedResult = cache[cacheKey] {
            return cachedResult
        }

        let result = BackgroundCalculationOfApiRequestResult(request: request, seedString: seedString)
        cache[cacheKey] = result
        
        return result
    }
}
