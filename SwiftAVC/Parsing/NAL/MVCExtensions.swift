//
//  MVCExtensions.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.14..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

// Multiview Video Coding NAL header extensions (spec Annex H)

struct MVCHeader {
    let nonIDRFlag: Bool
    let priorityID: Int
    let viewID: Int
    let temporalID: Int
    let anchorPicFlag: Bool
    let interViewFlag: Bool
    
    init(synelDictionary sd: SynelDictionary) {
        nonIDRFlag = sd.scalar(forKey: MVCHeaderSynel.nonIDRFlag) != 0;
        priorityID = sd.scalar(forKey: MVCHeaderSynel.priorityID);
        viewID = sd.scalar(forKey: MVCHeaderSynel.viewID);
        temporalID = sd.scalar(forKey: MVCHeaderSynel.temporalID);
        anchorPicFlag = sd.scalar(forKey: MVCHeaderSynel.anchorPicFlag) != 0;
        interViewFlag = sd.scalar(forKey: MVCHeaderSynel.interViewFlag) != 0;
    }
}

// spec H.7.4.1.1
struct MVCHeaderSynel {
    static let nonIDRFlag = Synel(name: "non_idr_flag", type: .Un(1))
    static let priorityID = Synel(name: "priority_id", type: .Un(6))
    static let viewID = Synel(name: "view_id", type: .Un(10))
    static let temporalID = Synel(name: "temporal_id", type: .Un(3))
    static let anchorPicFlag = Synel(name: "anchor_pic_flag", type: .Un(1))
    static let interViewFlag = Synel(name: "inter_view_flag", type: .Un(1))
    static let reservedOneBit = Synel(name: "reserved_one_bit", type: .Un(1)) { $0 == 1 }
}

// spec H.7.3.1.1
func parseNALUnitHeaderMVCExtension() -> H264Parse {
    return
        parseS(MVCHeaderSynel.nonIDRFlag) >-
        parseS(MVCHeaderSynel.priorityID) >-
        parseS(MVCHeaderSynel.viewID) >-
        parseS(MVCHeaderSynel.temporalID) >-
        parseS(MVCHeaderSynel.anchorPicFlag) >-
        parseS(MVCHeaderSynel.interViewFlag) >-
        parseS(MVCHeaderSynel.reservedOneBit)
}
