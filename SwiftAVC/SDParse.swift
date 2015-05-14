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
    var runSDParse: S -> (Either<E,A1>, S) { return self.runEitherState }
}

typealias SDSynelParse = EitherState<String, SDParseState, Int>
typealias SDStateParse = EitherState<String, SDParseState, SDParseState>
typealias SDUnitParse = EitherState<String, SDParseState, ()>


func parseS(synel: Synel) -> SDSynelParse {
    return parseWith({ (sd, syn, v) in sd.setScalar(v, forKey:syn) }, synel)
}

func parseA(synel: Synel) -> SDSynelParse {
    return parseWith({ (sd, syn, v) in sd.appendToArray(values: [v], forKey: syn) }, synel)
}

func parseM(synel: Synel, index: Int) -> SDSynelParse {
    return parseWith({ (sd, syn, v) in sd.addToValueMap(values: [index: v], forKey: syn) }, synel)
}

func parseWith(f: (SynelDictionary, Synel, Int) -> SynelDictionary, synel: Synel) -> SDSynelParse {
    return SDSynelParse.get() >>= { sdps in
        let bitParse = parseSynel(synel)
        let (bpResult, newBPS) = bitParse.runBitParse(sdps.bitParseState)
        
        switch bpResult {
            case .Left(let box): return SDSynelParse.fail(box.unbox())
            case .Right(let box):
                let value = box.unbox()
                let newSD = f(sdps.dictionary, synel, value)
                return SDSynelParse.put(SDParseState(bitPS: newBPS, dictionary: newSD)) >>
                    SDSynelParse.unit(value)
        }
    }
}

func parseForEach<A>(values: [A], parser: A -> SDSynelParse) -> SDUnitParse {
    var chain = SDSynelParse.unit(0)
    
    for value in values {
        chain = chain.bind({ _ in parser(value) })
    }
    
    return chain >> SDUnitParse.unit(())
}

func parseWhenSD(predicate: SynelDictionary -> Bool, parse: SDSynelParse) -> SDUnitParse {
    return SDSynelParse.get() >>= { sdps in
        if predicate(sdps.dictionary) {
            return parse >> SDUnitParse.unit(())
        }
        
        return SDUnitParse.unit(())
    }
}

func parseWhileSD(predicate: SynelDictionary -> Bool, parse: SDSynelParse) -> SDUnitParse {
    return SDSynelParse.get() >>= { sdps in
        if predicate(sdps.dictionary) {
            return parse >> parseWhileSD(predicate, parse)
        }
        
        return SDUnitParse.unit(())
    }
}

func parseWhen(predicate: SDParseState -> Bool, parse: SDSynelParse) -> SDUnitParse {
    return SDSynelParse.get() >>= { sdps in
        if predicate(sdps) {
            return parse >> SDUnitParse.unit(())
        }
        
        return SDUnitParse.unit(())
    }
}

func parseWhile(predicate: SDParseState -> Bool, parse: SDSynelParse) -> SDUnitParse {
    return SDSynelParse.get() >>= { sdps in
        if predicate(sdps) {
            return parse >> parseWhile(predicate, parse)
        }
        
        return SDUnitParse.unit(())
    }
}

