//
//  BackgroundCalculationOfApiRequestResult.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/08.
//

import Foundation
import Combine
import CryptoKit


/// The calculated result of an API request, which runs in the background
/// and is cached so that a request never causes more than one calculation.
class BackgroundCalculationOfApiRequestResult: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    @Published var ready: Bool = false
    @Published var successResponse: SuccessResponse? = nil
    @Published var result: Result<SuccessResponse,Error>? = nil
    let future: Future<SuccessResponse, Error>
    
    private func setSuccess(_ resultIfSuccess: SuccessResponse) {
        self.successResponse = resultIfSuccess
        self.result = .success(resultIfSuccess)
        self.ready = true
        self.sendChangeEventOnMainThread()
    }
    
    private func setError(_ error: Error) {
        self.result = .failure(error)
        self.ready = true
        self.sendChangeEventOnMainThread()
    }
    
    private init (_ resultFuture: Future<SuccessResponse, Error>) {
        self.future = resultFuture
        super.init()
        _ = future.sink(
            receiveCompletion: { completion in
                if case let .failure(error) = completion { self.setError(error) }
            }, receiveValue: { resultIfSuccess in self.setSuccess(resultIfSuccess)
        })
    }
    
    static var cache: [String: BackgroundCalculationOfApiRequestResult] = [:]
    
    static func precalculateForTestUseOnly(request: ApiRequest, seedString: String) {
        let cacheKeyPreimage: String = request.id + seedString
        let cacheKey = SHA256.hash(data: cacheKeyPreimage.data(using: .utf8)!).description
        var result: Result<SuccessResponse,Error>?
        do {
            try result = .success(request.execute(seedString: seedString))
        } catch {
            result = .failure(error)
        }
        
        let resultFuture = Future<SuccessResponse, Error>{ promise in promise(result!) }
        let r = BackgroundCalculationOfApiRequestResult(resultFuture)
        r.ready = true
        r.result = result
        if case let .success(sr) = result {
            r.successResponse = sr
        }
        cache[cacheKey] = r
    }
    
    static func get(request: ApiRequest, seedString: String) -> BackgroundCalculationOfApiRequestResult {
        let cacheKeyPreimage: String = request.id + seedString
        let cacheKey = SHA256.hash(data: cacheKeyPreimage.data(using: .utf8)!).description
        if let cachedResult = cache[cacheKey] {
            return cachedResult
        }

        let resultFuture = Future<SuccessResponse, Error>{ promise in
            DispatchQueue.global(qos: .background).async {
                do {
                    let result = try request.execute(seedString: seedString)
                    DispatchQueue.main.async {
                        promise(.success(result))
                    }
                } catch {
                    DispatchQueue.main.async {
                        promise(.failure(error))
                    }
                }
            }
        }
        let result = BackgroundCalculationOfApiRequestResult(resultFuture)
        cache[cacheKey] = result
        
        return result
    }
}
