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
    @Published var result: Result<SuccessResponse,Error> = .failure(BackgroundCalculationError.inProgress) {
        didSet { self.sendChangeEventOnMainThread() }
    }
    private var onResultCallbacks: [(Result<SuccessResponse, Error>) throws -> Void] = []
    private var request: ApiRequest
    private var seedString: String?
    
    private func setResult(_ result: Result<SuccessResponse, Error>) {
        self.result = result
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
    
    private init(request: ApiRequest, seedString: String? = nil) {
        self.request = request
        super.init()
        if let seedString = seedString {
            execute(seedString: seedString)
        }
    }
    
    func execute(seedString: String) {
        if (self.seedString == seedString) {
            // Already executing
            return
        }
        self.seedString = seedString
        DispatchQueue.global(qos: .background).async {
            do {
                let successResponse = try self.request.execute(seedString: seedString)
                DispatchQueue.main.async {
                    if (self.seedString == seedString) {
                        self.setResult(.success(successResponse))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if (self.seedString == seedString) {
                        self.setResult(.failure(error))
                    }
                }
            }
        }
    }
    
    static func get(request: ApiRequest, seedString: String? = nil) -> BackgroundCalculationOfApiRequestResult {
        let cacheKeyPreimage: String = request.id
        let cacheKey = SHA256.hash(data: cacheKeyPreimage.data(using: .utf8)!).description
        if let cachedResult = cache[cacheKey] {
            if let seedString = seedString {
                cachedResult.execute(seedString: seedString)
            }
            return cachedResult
        }

        let result = BackgroundCalculationOfApiRequestResult(request: request, seedString: seedString)
        cache[cacheKey] = result
        if let seedString = seedString {
            result.execute(seedString: seedString)
        }
        return result
    }
}
