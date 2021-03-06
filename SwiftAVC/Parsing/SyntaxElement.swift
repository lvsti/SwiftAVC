//
//  SyntaxElement.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.08..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

enum SynelType {
    case AEv
    case B8
    case CEv
    case Fn(Int)
    case In(Int)
    case MEv
    case SEv
    case TEv(Int)
    case Un(Int)
    case UEv
}

extension SynelType: Printable {
    var description: String {
        get {
            switch self {
            case .AEv: return "ae(v)"
            case .B8: return "b(8)"
            case .CEv: return "ce(v)"
            case .Fn(let n): return "f(\(n))"
            case .In(let n): return "i(\(n))"
            case .MEv: return "me(v)"
            case .SEv: return "se(v)"
            case .TEv(let r): return "te(v|\(r))"
            case .Un(let n): return "u(\(n))"
            case .UEv: return "ue(v)"
            }
        }
    }
}

let kSynelCategoryAll = [Int]()

struct Synel: Equatable, Comparable {
    let name: String
    let type: SynelType
    let categories: [Int]
    let validate: Int -> Bool
    
    init(name: String, type: SynelType, categories: [Int], validate: (Int) -> Bool = {_ in true}) {
        self.name = name
        self.type = type
        self.categories = categories
        self.validate = validate
    }

    init(name: String, type: SynelType, validate: (Int) -> Bool = {_ in true}) {
        self.name = name
        self.type = type
        self.categories = kSynelCategoryAll
        self.validate = validate
    }
}

extension Synel: Printable {
    var description: String {
        get { return "\(name) C\(categories) :: \(type)" }
    }
}

extension Synel: Hashable {
    var hashValue: Int {
        get { return name.hashValue }
    }
}

func ==(lhs: Synel, rhs: Synel) -> Bool {
    return lhs.name == rhs.name
}

func <(lhs: Synel, rhs: Synel) -> Bool {
    return lhs.name < rhs.name
}

func parseBits(forSynelType type: SynelType) -> BitParse {
    switch type {
    case .AEv: return parseAEv()
    case .B8: return parseB8()
    case .CEv: return parseCEv()
    case .Fn(let n): return parseFn(n)
    case .In(let n): return parseIn(n)
    case .MEv: return parseMEv()
    case .SEv: return parseSEv()
    case .TEv(let r): return parseTEv(r)
    case .Un(let n): return parseUn(n)
    case .UEv: return parseUEv()
    }
}

func parseSynel(synel: Synel) -> BitParse {
    let parse = parseBits(forSynelType: synel.type)
    return parse >>- { value in
        println("parsing \(synel) = \(value)")
        return synel.validate(value) ?
            BitParse.unit(value) :
            BitParse.fail("validation of synel '\(synel)' failed, value = \(value)")
    }
}


