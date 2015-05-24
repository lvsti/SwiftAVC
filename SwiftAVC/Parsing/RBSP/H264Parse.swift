//
//  H264Parse.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.23..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct H264ParseState {
    let sdParseState: SDParseState
    let context: H264Context
    
    var dictionary: SynelDictionary { get { return sdParseState.dictionary } }
    var bitParseState: BitParseState { get { return sdParseState.bitParseState } }
    
    init(parseState: SDParseState, context: H264Context) {
        self.sdParseState = parseState
        self.context = context
    }
    
    func mutateSD(newSD: SynelDictionary) -> H264ParseState {
        let newSDPS = SDParseState(bitPS: self.sdParseState.bitParseState, dictionary: newSD)
        return H264ParseState(parseState: newSDPS, context: self.context)
    }
}

typealias H264ParseError = String

extension EitherState {
    var runH264Parse: S -> (Either<E,A>, S) { return self.runEitherState }
}

typealias H264Parse = EitherState<H264ParseError, H264ParseState, ()>

func h264Lambda(f: H264ParseState -> H264Parse) -> (H264ParseState -> H264Parse) {
    return f
}

func parseS(synel: Synel) -> H264Parse {
    return parseWith({ (sd, syn, v) in sd.setScalar(v, forKey:syn) }, synel)
}

func parseA(synel: Synel) -> H264Parse {
    return parseWith({ (sd, syn, v) in sd.appendToArray(values: [v], forKey: syn) }, synel)
}

func parseM(synel: Synel, index: Int) -> H264Parse {
    return parseWith({ (sd, syn, v) in sd.addToValueMap(values: [index: v], forKey: syn) }, synel)
}

func parseWith(f: (SynelDictionary, Synel, Int) -> SynelDictionary, synel: Synel) -> H264Parse {
    return H264Parse.get() >>- { hps in
        let bitParse = parseSynel(synel)
        let (bpResult, newBPS) = bitParse.runBitParse(hps.bitParseState)
        
        switch bpResult {
            case .Left(let box): return H264Parse.fail(box.unbox())
            case .Right(let box):
                let value = box.unbox()
                let newSD = f(hps.dictionary, synel, value)
                let newSDPS = SDParseState(bitPS: newBPS, dictionary: newSD)
                return H264Parse.put(H264ParseState(parseState: newSDPS, context: hps.context))
        }
    }
}

func parseForEach<A>(values: [A], parser: A -> H264Parse) -> H264Parse {
    var chain = H264Parse.unit(())
    
    for value in values {
        chain = chain >- parser(value)
    }
    
    return chain
}

func parseWhenSD(predicate: SynelDictionary -> Bool, parse: H264Parse) -> H264Parse {
    return H264Parse.get() >>- { hps in
        if predicate(hps.dictionary) {
            return parse
        }
        
        return H264Parse.unit(())
    }
}

func parseWhileSD(predicate: SynelDictionary -> Bool, parse: H264Parse) -> H264Parse {
    return H264Parse.get() >>- { hps in
        if predicate(hps.dictionary) {
            return parse >- parseWhileSD(predicate, parse)
        }
        
        return H264Parse.unit(())
    }
}

func parseWhen(predicate: H264ParseState -> Bool, parse: H264Parse) -> H264Parse {
    return H264Parse.get() >>- { hps in
        if predicate(hps) {
            return parse
        }
        
        return H264Parse.unit(())
    }
}

func parseWhile(predicate: H264ParseState -> Bool, parse: H264Parse) -> H264Parse {
    return H264Parse.get() >>- { hps in
        if predicate(hps) {
            return parse >- parseWhile(predicate, parse)
        }
        
        return H264Parse.unit(())
    }
}
