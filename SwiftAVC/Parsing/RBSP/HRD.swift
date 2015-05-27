//
//  HRD.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.27..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// HRD parameters (spec Annex E)
// -----------------------------------------------------------------------------

// spec E.2.2
struct HRDSynel {
    static let cpbCntMinus1 = Synel(name: "cpb_cnt_minus1", type: .UEv, categories: [0,5]) { $0 <= 31 }
    static let bitRateScale = Synel(name: "bit_rate_scale", type: .Un(4), categories: [0,5])
    static let cpbSizeScale = Synel(name: "cpb_size_scale", type: .Un(4), categories: [0,5])
    static let bitRateValueMinus1 = Synel(name: "bit_rate_value_minus1", type: .UEv, categories: [0,5]) { $0 <= 0xfffffffe }
    static let cpbSizeValueMinus1 = Synel(name: "cpb_size_value_minus1", type: .UEv, categories: [0,5]) { $0 <= 0xfffffffe }
    static let cbrFlag = Synel(name: "cbr_flag", type: .Un(1), categories: [0,5])
    static let initialCPBRemovalDelayLengthMinus1 = Synel(name: "initial_cpb_removal_delay_length_minus1", type: .Un(5), categories: [0,5])
    static let cpbRemovalDelayLengthMinus1 = Synel(name: "cpb_removal_delay_length_minus1", type: .Un(5), categories: [0,5])
    static let dpbOutputDelayLengthMinus1 = Synel(name: "dpb_output_delay_length_minus1", type: .Un(5), categories: [0,5])
    static let timeOffsetLength = Synel(name: "time_offset_length", type: .Un(5), categories: [0,5])
}

// spec E.1.2
func parseHRDParameters() -> H264Parse {
    return
        parseS(HRDSynel.cpbCntMinus1) >-
        parseS(HRDSynel.bitRateScale) >-
        parseS(HRDSynel.cpbSizeScale) >-
        H264Parse.get() >>-
        h264Lambda { hps in
            let cpbCntMinus1 = hps.dictionary.scalar(forKey: HRDSynel.cpbCntMinus1)

            return
                parseForEach([Int](0...cpbCntMinus1)) { _ in
                    parseA(HRDSynel.bitRateValueMinus1) >-
                    parseA(HRDSynel.cpbSizeValueMinus1) >-
                    parseA(HRDSynel.cbrFlag)
                }
        } >-
        parseS(HRDSynel.initialCPBRemovalDelayLengthMinus1) >-
        parseS(HRDSynel.cpbRemovalDelayLengthMinus1) >-
        parseS(HRDSynel.dpbOutputDelayLengthMinus1) >-
        parseS(HRDSynel.timeOffsetLength)
}

