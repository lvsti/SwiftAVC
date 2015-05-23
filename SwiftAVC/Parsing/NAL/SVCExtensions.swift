//
//  SVCExtensions.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.05.14..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

// Scalable Video Coding NAL header extensions (spec Annex G)

struct SVCHeader {
    let idrFlag: Bool
    let priorityID: Int
    let noInterLayerPredFlag: Bool
    let dependencyID: Int
    let qualityID: Int
    let temporalID: Int
    let useRefBasePicFlag: Bool
    let discardableFlag: Bool
    let outputFlag: Bool
    
    init(synelDictionary sd: SynelDictionary) {
        idrFlag = sd.scalar(forKey: SVCHeaderSynel.idrFlag) != 0;
        priorityID = sd.scalar(forKey: SVCHeaderSynel.priorityID);
        noInterLayerPredFlag = sd.scalar(forKey: SVCHeaderSynel.noInterLayerPredFlag) != 0;
        dependencyID = sd.scalar(forKey: SVCHeaderSynel.dependencyID);
        qualityID = sd.scalar(forKey: SVCHeaderSynel.qualityID);
        temporalID = sd.scalar(forKey: SVCHeaderSynel.temporalID);
        useRefBasePicFlag = sd.scalar(forKey: SVCHeaderSynel.useRefBasePicFlag) != 0;
        discardableFlag = sd.scalar(forKey: SVCHeaderSynel.discardableFlag) != 0;
        outputFlag = sd.scalar(forKey: SVCHeaderSynel.outputFlag) != 0;
    }
}

// spec G.7.4.1.1
struct SVCHeaderSynel {
    static let idrFlag = Synel(name: "idr_flag", type: .Un(1))
    static let priorityID = Synel(name: "priority_id", type: .Un(6))
    static let noInterLayerPredFlag = Synel(name: "no_inter_layer_pred_flag", type: .Un(1))
    static let dependencyID = Synel(name: "dependency_id", type: .Un(3))
    static let qualityID = Synel(name: "quality_id", type: .Un(4))
    static let temporalID = Synel(name: "temporal_id", type: .Un(3))
    static let useRefBasePicFlag = Synel(name: "use_ref_base_pic_flag", type: .Un(1))
    static let discardableFlag = Synel(name: "discardable_flag", type: .Un(1))
    static let outputFlag = Synel(name: "output_flag", type: .Un(1))
    static let reservedThree2bits = Synel(name: "reserved_three_2bits", type: .Un(2)) { $0 == 3 }
}

// spec G.7.3.1.1
func parseNALUnitHeaderSVCExtension() -> SDParse {
    return
        parseS(SVCHeaderSynel.idrFlag) >-
        parseS(SVCHeaderSynel.priorityID) >-
        parseS(SVCHeaderSynel.noInterLayerPredFlag) >-
        parseS(SVCHeaderSynel.dependencyID) >-
        parseS(SVCHeaderSynel.qualityID) >-
        parseS(SVCHeaderSynel.temporalID) >-
        parseS(SVCHeaderSynel.useRefBasePicFlag) >-
        parseS(SVCHeaderSynel.discardableFlag) >-
        parseS(SVCHeaderSynel.outputFlag) >-
        parseS(SVCHeaderSynel.reservedThree2bits)
}

