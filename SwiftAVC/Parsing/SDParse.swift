//
//  SDParse.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.13..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct SDParseState {
    let bitParseState: BitParseState
    let dictionary: SynelDictionary
    
    init(bitPS: BitParseState, dictionary: SynelDictionary) {
        self.bitParseState = bitPS
        self.dictionary = dictionary
    }
}

typealias SDParseError = String

extension EitherState {
    var runSDParse: S -> (Either<E,A>, S) { return self.runEitherState }
}

typealias SDParse = EitherState<String, SDParseState, ()>

func sdLambda(f: SDParseState -> SDParse) -> (SDParseState -> SDParse) {
    return f
}
