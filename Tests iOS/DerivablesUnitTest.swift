//
//  DerivablesUnitTest.swift
//  Tests iOS
//
//  Created by Angelos Veglektsis on 7/30/22.
//

import XCTest

// These tests should match the
// [Reference Unit Tests in Android](https://github.com/dicekeys/dicekeys-android/blob/main/app/src/test/java/org/dicekeys/app/CanonicalizeJsonRecipeUnitTests.kt)
// and its functionality should not be changed without ensuring that the reference implementation
// and dependent implementations are changed to match.

class DerivablesUnitTest: XCTestCase {

    let canolicalizationTestVector = [
        
        // Order fields correctly
        ["{\"#\":3,\"allow\":[{\"host\":\"*.example.com\"}]}" , "{\"allow\":[{\"host\":\"*.example.com\"}],\"#\":3}",],
        // Order fields correctly
        ["{\"#\":3,\"allow\":[{\"host\":\"*.example.com\"}]}" , "{\"allow\":[{\"host\":\"*.example.com\"}],\"#\":3}"],
        // Order fields correctly
        ["{\"#\":3,\"allow\":[{\"host\":\"*.example.com\"}],\"purpose\":\"Life? Don't talk to me about life!\" }" , "{\"purpose\":\"Life? Don't talk to me about life!\",\"allow\":[{\"host\":\"*.example.com\"}],\"#\":3}"],
        // Order fields in sub-object (allow) correctly
        ["{\"allow\":[{\"paths\":[\"lo\", \"yo\"],\"host\":\"*.example.com\"}]}" , "{\"allow\":[{\"host\":\"*.example.com\",\"paths\":[\"lo\",\"yo\"]}]}"],
        // Remove white space correctly
        [" {  \"allow\" : [  {\"host\"\n:\"*.example.com\"}\t ]    }\n\n" , "{\"allow\":[{\"host\":\"*.example.com\"}]}"],
        // Lots of fields to order correctly, including an empty object with all-caps field name
        ["{\"allow\":[{\"paths\":[\"lo\", \"yo\"],\"host\":\"*.example.com\"}],\"#\":3, \"purpose\":\"Don't know\", \"lengthInChars\":3, \"lengthInBytes\": 15, \"UNANTICIPATED_CAPITALIZED_FIELD\":{}}" , "{\"purpose\":\"Don't know\",\"UNANTICIPATED_CAPITALIZED_FIELD\":{},\"allow\":[{\"host\":\"*.example.com\",\"paths\":[\"lo\",\"yo\"]}],\"lengthInBytes\":15,\"lengthInChars\":3,\"#\":3}"],
        // Lots of fields to order correctly, including an empty array with all-caps field name
        ["{\"allow\":[{\"paths\":[\"lo\", \"yo\"],\"host\":\"*.example.com\"}],\"#\":3, \"purpose\":\"Don't know\", \"lengthInChars\":3, \"lengthInBytes\": 15, \"UNANTICIPATED_CAPITALIZED_FIELD\":[ ] }" , "{\"purpose\":\"Don't know\",\"UNANTICIPATED_CAPITALIZED_FIELD\":[],\"allow\":[{\"host\":\"*.example.com\",\"paths\":[\"lo\",\"yo\"]}],\"lengthInBytes\":15,\"lengthInChars\":3,\"#\":3}"],
        // objects and array parsing
        ["{ \"silly\":[{\"pointless\":[ \"spacing in\", \"out\"]}]}" , "{\"silly\":[{\"pointless\":[\"spacing in\",\"out\"]}]}"],
        // objects and array parsing
        ["{ \"silly\":[{\"pointless\":[ \"spacing in\", \"out\"]}],   \"crazy\":3}" , "{\"crazy\":3,\"silly\":[{\"pointless\":[\"spacing in\",\"out\"]}]}"]
    ]
    

    func test_canonicalizeRecipeJson(){
        canolicalizationTestVector.forEach { test in
            XCTAssertEqual(test[1], test[0].canonicalizeRecipeJson())
        }
    }
}
