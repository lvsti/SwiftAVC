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

func parseS(synel: Synel) -> SDParse {
    return parseWith({ (sd, syn, v) in sd.setScalar(v, forKey:syn) }, synel)
}

func parseA(synel: Synel) -> SDParse {
    return parseWith({ (sd, syn, v) in sd.appendToArray(values: [v], forKey: syn) }, synel)
}

func parseM(synel: Synel, index: Int) -> SDParse {
    return parseWith({ (sd, syn, v) in sd.addToValueMap(values: [index: v], forKey: syn) }, synel)
}

func parseWith(f: (SynelDictionary, Synel, Int) -> SynelDictionary, synel: Synel) -> SDParse {
    return SDParse.get() >>- { sdps in
        let bitParse = parseSynel(synel)
        let (bpResult, newBPS) = bitParse.runBitParse(sdps.bitParseState)
        
        switch bpResult {
            case .Left(let box): return SDParse.fail(box.unbox())
            case .Right(let box):
                let value = box.unbox()
                let newSD = f(sdps.dictionary, synel, value)
                return SDParse.put(SDParseState(bitPS: newBPS, dictionary: newSD))
        }
    }
}

func parseForEach<A>(values: [A], parser: A -> SDParse) -> SDParse {
    var chain = SDParse.unit(())
    
    for value in values {
        chain = chain >- parser(value)
    }
    
    return chain
}

func parseWhenSD(predicate: SynelDictionary -> Bool, parse: SDParse) -> SDParse {
    return SDParse.get() >>- { sdps in
        if predicate(sdps.dictionary) {
            return parse
        }
        
        return SDParse.unit(())
    }
}

func parseWhileSD(predicate: SynelDictionary -> Bool, parse: SDParse) -> SDParse {
    return SDParse.get() >>- { sdps in
        if predicate(sdps.dictionary) {
            return parse >- parseWhileSD(predicate, parse)
        }
        
        return SDParse.unit(())
    }
}

func parseWhen(predicate: SDParseState -> Bool, parse: SDParse) -> SDParse {
    return SDParse.get() >>- { sdps in
        if predicate(sdps) {
            return parse
        }
        
        return SDParse.unit(())
    }
}

func parseWhile(predicate: SDParseState -> Bool, parse: SDParse) -> SDParse {
    return SDParse.get() >>- { sdps in
        if predicate(sdps) {
            return parse >- parseWhile(predicate, parse)
        }
        
        return SDParse.unit(())
    }
}

