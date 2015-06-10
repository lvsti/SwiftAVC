//
//  SynelDictionary.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.07..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

public struct SynelDictionary {
    typealias SDStorage = [Synel:[SynelValue]]
    
    private let _dictionary: SDStorage
    
    private init(dictionary: SDStorage) {
        _dictionary = dictionary
    }
    
    init() {
        _dictionary = SDStorage()
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
    
    func scalar(forKey key: Synel) -> SynelValue? {
        return array(forKey: key)?[0]
    }
    
    func array(forKey key: Synel) -> [SynelValue]? {
        return _dictionary[key]
    }
    
    subscript(key: Synel) -> [SynelValue]? {
        return _dictionary[key]
    }
    
    // setters
    
    func setScalar(value: SynelValue, forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        copyDict[key] = [value]
        return SynelDictionary(dictionary: copyDict)
    }

    func setArray(values: [SynelValue], forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        copyDict[key] = values
        return SynelDictionary(dictionary: copyDict)
    }

    // mutating collections
    
    func addScalar(value: SynelValue, forKey key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        if let v = _dictionary[key] {
            copyDict[key] = v + [value]
        } else {
            copyDict[key] = [value]
        }
        return SynelDictionary(dictionary: copyDict)
    }

    func removeKey(key: Synel) -> SynelDictionary {
        var copyDict = _dictionary
        copyDict.removeValueForKey(key)
        return SynelDictionary(dictionary: copyDict)
    }
}

extension SynelDictionary: Printable {
    public var description: String { get { return _dictionary.description } }
}


