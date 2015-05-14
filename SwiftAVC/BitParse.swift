//
//  BitParse.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct BitParseState {
    let bitstream: Bitstream
    let offset: Int
    
    init(bitstream: Bitstream, offset: Int) {
        self.bitstream = bitstream
        self.offset = offset
    }
}

typealias BitParseError = String
typealias BitParse = EitherState<BitParseError, BitParseState, Int>

extension EitherState {
    var runBitParse: S -> (Either<E,A1>, S) { return self.runEitherState }
}


func parseAEv() -> BitParse {
    return BitParse.fail("AE(v): not implemented")
}

func parseB8() -> BitParse {
    return parseFn(8);
}

func parseCEv() -> BitParse {
    return BitParse.fail("CE(v): not implemented")
}

func parseFn(n: Int) -> BitParse {
    if n > sizeof(Int)*8 {
        return BitParse.fail("F(n): integer overflow (\(n))")
    }
    
    return BitParse { s0 in
        let s1 = BitParseState(bitstream: s0.bitstream, offset: s0.offset + n)
        let bits = s0.bitstream.read(s0.offset, count: n)
        if let bits = bits {
            return (.Right(Box(bits)), s1)
        }
        let msg = "F(n): unexpected EOS: expected \(n), remaining \(s0.bitstream.length - s0.offset)"
        return (.Left(Box(msg)), s1)
    }
}

func parseIn(n: Int) -> BitParse {
    return parseFn(n) >>= { x in BitParse.unit(extendSign(x, n)) }
}

func parseMEv() -> BitParse {
    return BitParse.fail("ME(v): use UE(v) and refer to 9.1.2 for the mapping")
}

func parseSEv() -> BitParse {
    return parseUEv() >>= { ueValue in
        let absValue = (ueValue + 1) >> 1
        let seValue = ueValue & 1 == 1 ? absValue : -absValue
        return BitParse.unit(seValue)
    }
}

func parseTEv(r: Int) -> BitParse {
    if r > 1 {
        return parseUEv()
    } else if r == 1 {
        return parseFn(1) >>= { x in BitParse.unit(1 - x) }
    }
    
    return BitParse.fail("TE(v): invalid range (\(r))")
}

func parseUn(n: Int) -> BitParse {
    return parseFn(n)
}

func parseUEv() -> BitParse {
    return BitParse { s in
        var leadingZeroBitCount = 0
        var offset = s.offset
        
        // leading zero bits
        while (true) {
            if let bit = s.bitstream.read(offset, count: 1) {
                ++offset
                if bit == 0 {
                    ++leadingZeroBitCount
                } else {
                    break
                }
            } else {
                let msg = "UE(v): unexpected EOS"
                return (.Left(Box(msg)), BitParseState(bitstream: s.bitstream, offset: offset))
            }
        }
        
        // mantissa
        if let mantissa = s.bitstream.read(offset, count: leadingZeroBitCount) {
            offset += leadingZeroBitCount
            let value = (1 << leadingZeroBitCount) - 1 + mantissa
            return (.Right(Box(value)), BitParseState(bitstream: s.bitstream, offset: offset))
        } else {
            let msg = "UE(v): incomplete exp-Golomb codeword"
            return (.Left(Box(msg)), BitParseState(bitstream: s.bitstream, offset: offset))
        }
    }
}

