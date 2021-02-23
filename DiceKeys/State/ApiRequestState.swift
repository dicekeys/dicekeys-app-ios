//
//  ApiRequestState.swift
//  DiceKeys
//
//  Created by Stuart Schechter on 2021/02/07.
//

import Foundation

fileprivate struct ApiRequestWithCompletionCallback {
    let request: ApiRequest
    let callback: (Result<SuccessResponse, Error>) -> Void
}

final class ApiRequestState: ObservableObjectUpdatingOnAllChangesToUserDefaults {
    static private(set) var singleton = ApiRequestState()

    @Published private var apiRequestApprovalQueue: [ApiRequestWithCompletionCallback] = []
    
    fileprivate var requestForUserToApproveWithCallback: ApiRequestWithCompletionCallback? {
        return apiRequestApprovalQueue.first
    }
    var requestForUserToApprove: ApiRequest? { requestForUserToApproveWithCallback?.request }

    func askUserToApproveApiRequest(_ request: ApiRequest, _ callback: @escaping (Result<SuccessResponse, Error>) -> Void) -> Void {
        apiRequestApprovalQueue.append(ApiRequestWithCompletionCallback(request: request, callback: callback))
        self.sendChangeEventOnMainThread()
    }
    
    private func removeApiRequestApproval() {
        apiRequestApprovalQueue.removeFirst()
        self.sendChangeEventOnMainThread()
    }

    /// Complete the request and remove it from the set of pending requests
    func completeApiRequest(_ result: Result<SuccessResponse, Error>) {
        // Send the resposne
        self.requestForUserToApproveWithCallback?.callback(result)
        // Remove the request
        self.removeApiRequestApproval()
    }
}
