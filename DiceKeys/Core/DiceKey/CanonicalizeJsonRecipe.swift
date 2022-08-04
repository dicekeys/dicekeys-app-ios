//
//  CanonicalizeJsonRecipe.swift
//  DiceKeys
//
//  Created by Angelos Veglektsis on 7/29/22.
//

import Foundation

// These functions should match the
// [Reference Implementation in TypeScript](https://github.com/dicekeys/dicekeys-app-typescript/blob/main/web/src/dicekeys/canonicalizeRecipeJson.ts)
// and its functionality should not be changed without ensuring that the reference implementation
// and dependent implementations are changed to match.

func compareObjectFieldNames(a: String, b: String) -> Bool{
    // The "#" (sequence number) field always comes last
    if(a == "#") {
        return false
    }else if(b == "#"){
        return true
    }
    
    // The "purpose" field always comes first
    else if(a == "purpose") {
        return true
    } else if(b == "purpose") {
        return false
    }
    // Otherwise, sort in alphabetical order
    else{
        return a < b
    }
}

func toCanonicalizeRecipeJson(_ json: Any) -> String{
    if ((json as? NSNull) != nil)  {
         return "null"
    }
    
    if let json = json as? Array<Any> {
        let values = json.map { data in
            toCanonicalizeRecipeJson(data)
        }.joined(separator: ",")
        
        return "[\(values)]"
    }
    
    if let json = json as? Dictionary<String, Any> {
        // Sort keys
        let keys = json.keys.sorted { a, b in
            return compareObjectFieldNames(a: a, b: b)
        }
        let values : [String] = keys.map { key in
            return "\"\(key)\":\(toCanonicalizeRecipeJson(json[key]!))"
        }
                
        return "{\(values.joined(separator: ","))}"
    }
    
    if let json = json as? String{
        return "\"" + json + "\""
    }else {
        return "\(json)"
    }
}
