//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by bakhtiyor on 17/12/20.
//

import XCTest
import SeededCrypto

class Tests_iOS: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testIssue56PasswordCannotBeDerived() throws {
        let recipeJson = "{\"allow\":[{\"host\":\"*.exampl.com\"}],\"lengthInChars\":0}"
        let password = try Password.deriveFromSeed(withSeedString: "this string is seedy", recipe: recipeJson)
        XCTAssertNotNil(password)
        XCTAssertNotNil(password.password)
    }
// TODO: outdated test, should be updated
    func testGetPasswordApi() throws {
//        handleUrlApiRequest(
//            incomingRequestUrl: URL(string: "https://dicekeys.app/?command=getPassword&requestId=1&respondTo=https%3A%2F%2Fpwmgr.app%2F--derived-secret-api--%2F&recipe=%7B%22allow%22%3A%5B%7B%22host%22%3A%22pwmgr.app%22%7D%5D%7D&recipeMayBeModified=false")!,
//            approveApiRequest: { _, callback in
//                callback(.success("A1tB2rC3bD4lE5tF6rG1bH2lI3tJ4rK5bL6lM1tN2rO3bP4lR5tS6rT1bU2lV3tW4rX5bY6lZ1t"))
//            },
//            sendResponse: { baseurl, parameters in
//                guard let passwordJson = parameters["passwordJson"] else {
//                    XCTFail("passwordJson not set")
//                    return
//                }
//                guard let password = try? Password.from(json: passwordJson).password else {
//                    XCTFail("couldn't parse passwordJson")
//                    return
//                }
//                XCTAssertEqual(password, "15-Agent-knelt-doozy-agile-fable-harsh-arose-ionic-dense-getup-until-tacky-books-lucid-savor")
//            }
//        )
    }

}
