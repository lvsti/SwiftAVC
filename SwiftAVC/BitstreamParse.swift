//
//  BitstreamParse.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct BitstreamParseState {
    let bitstream: Bitstream
    let offset: Int
    
    init(bitstream: Bitstream, offset: Int) {
        self.bitstream = bitstream
        self.offset = offset
    }
}

typealias BitstreamParse = EitherState<String, BitstreamParseState, Int>


func parseAEv() -> BitstreamParse {
    return BitstreamParse.fail("AE(v): not implemented")
}

func parseB8() -> BitstreamParse {
    return parseFn(8);
}

func parseCEv() -> BitstreamParse {
    return BitstreamParse.fail("CE(v): not implemented")
}

func parseFn(n: Int) -> BitstreamParse {
    if n > sizeof(Int)*8 {
        return BitstreamParse.fail("F(n): integer overflow (\(n))")
    }
    
    return BitstreamParse { s0 in
        let s1 = BitstreamParseState(bitstream: s0.bitstream, offset: s0.offset + n)
        let bits = s0.bitstream.read(s0.offset, count: n)
        if let bits = bits {
            return (.Right(Box(bits)), s1)
        }
        let msg = "F(n): unexpected EOS: expected \(n), remaining \(s0.bitstream.length - s0.offset)"
        return (.Left(Box(msg)), s1)
    }
}

func parseIn(n: Int) -> BitstreamParse {
    return parseFn(n).bind({ x in BitstreamParse.unit(extendSign(x, n)) })
}

func parseMEv() -> BitstreamParse {
    return BitstreamParse.fail("ME(v): use UE(v) and refer to 9.1.2 for the mapping")
}

func parseSEv() -> BitstreamParse {
    return parseUEv().bind({ ueValue in
        let absValue = (ueValue + 1) >> 1
        let seValue = ueValue & 1 == 1 ? absValue : -absValue
        return BitstreamParse.unit(seValue)
    })
}

func parseTEv(r: Int) -> BitstreamParse {
    if r > 1 {
        return parseUEv()
    } else if r == 1 {
        return parseFn(1).bind({ x in BitstreamParse.unit(1 - x) })
    }
    
    return BitstreamParse.fail("TE(v): invalid range (\(r))")
}

func parseUn(n: Int) -> BitstreamParse {
    return parseFn(n)
}

func parseUEv() -> BitstreamParse {
    return BitstreamParse { s in
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
                return (.Left(Box(msg)), BitstreamParseState(bitstream: s.bitstream, offset: offset))
            }
        }
        
        // mantissa
        if let mantissa = s.bitstream.read(offset, count: leadingZeroBitCount) {
            offset += leadingZeroBitCount
            let value = (1 << leadingZeroBitCount) - 1 + mantissa
            return (.Right(Box(value)), BitstreamParseState(bitstream: s.bitstream, offset: offset))
        } else {
            let msg = "UE(v): incomplete exp-Golomb codeword"
            return (.Left(Box(msg)), BitstreamParseState(bitstream: s.bitstream, offset: offset))
        }
    }
}

