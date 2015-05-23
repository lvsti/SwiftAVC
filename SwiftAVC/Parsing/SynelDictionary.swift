//
//  SynelDictionary.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.12..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

enum SynelValue {
    case Scalar(Int)
    case Array([Int])
    case ValueMap([Int:Int])
}

struct SynelDictionary {
    private let _dictionary: [Synel:SynelValue]
    
    private init(dictionary: [Synel:SynelValue] = [:]) {
        _dictionary = dictionary
    }
    
    static func empty() -> SynelDictionary {
        return SynelDictionary()
    }
    
    func hasKey(key: Synel) -> Bool {
        return _dictionary[key] != nil
    }
    
    func hasKeys(keys: [Synel]) -> Bool {
        for key in keys {
            if _dictionary[key] == nil {
                return false
            }
        }
        return true
    }

    // getters
    
    func scalar(forKey key: Synel) -> Int {
        switch _dictionary[key]! {
        case .Scalar(let value): return value
        default: assertionFailure("\(key) is not a scalar")
        }
    }
    
    func array(forKey key: Synel) -> [Int] {
        switch _dictionary[key]! {
        case .Array(let values): return values
        default: assertionFailure("\(key) is not an array")
        }
    }

    func valueMap(forKey key: Synel) -> [Int:Int] {
        switch _dictionary[key]! {
        case .ValueMap(let values): return values
        default: assertionFailure("\(key) is not a map")
        }
    }
    
    // setters
    
    func setScalar(value: Int, forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        copyDict[key] = .Scalar(value)
        return SynelDictionary(dictionary: copyDict)
    }
    
    func setArray(values: [Int], forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        copyDict[key] = .Array(values)
        return SynelDictionary(dictionary: copyDict)
    }

    func setValueMap(values: [Int:Int], forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        copyDict[key] = .ValueMap(values)
        return SynelDictionary(dictionary: copyDict)
    }

    // mutating collections
    
    func appendToArray(values newValues: [Int], forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        var oldValues = [Int]()
        
        if let synelValue = copyDict[key] {
            switch synelValue {
            case .Array(let values): oldValues = values
            default: assertionFailure("\(key) is not an array")
            }
        }

        copyDict[key] = .Array(oldValues + newValues)
        return SynelDictionary(dictionary: copyDict)
    }

    func addToValueMap(values newValues: [Int:Int], forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        var oldValues = [Int:Int]()
        
        if let synelValue = copyDict[key] {
            switch synelValue {
            case .ValueMap(let values): oldValues = values
            default: assertionFailure("\(key) is not a map")
            }
        }
        
        for newKey in newValues.keys {
            oldValues[newKey] = newValues[newKey]
        }
        
        copyDict[key] = .ValueMap(oldValues)
        return SynelDictionary(dictionary: copyDict)
    }

}
