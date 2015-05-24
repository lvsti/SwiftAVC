//
//  RBSP.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.24..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct RBSPSynel {
    static let rbspStopOneBit = Synel(name: "rbsp_stop_one_bit", type: .Fn(1)) { $0 == 1 }
    static let rbspAlignmentZeroBit = Synel(name: "rbsp_alignment_zero_bit", type: .Fn(1)) { $0 == 0 }
}

// spec 7.3.2.11
func parseRBSPTrailingBits() -> H264Parse {
    return
        parseS(RBSPSynel.rbspStopOneBit) >-
        parseWhile({ $0.bitParseState.offset % 8 != 0 }, parseS(RBSPSynel.rbspAlignmentZeroBit))
}

