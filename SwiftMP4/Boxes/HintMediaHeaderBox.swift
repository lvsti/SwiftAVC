//
//  HintMediaHeaderBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.06..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct HintMediaHeaderBox {
    static let maxPDUSize = Synel(name: "maxPDUSize", type: (.u16, 1))
    static let avgPDUSize = Synel(name: "avgPDUSize", type: (.u16, 1))
    static let maxBitrate = Synel(name: "maxbitrate", type: (.u32, 1))
    static let avgBitrate = Synel(name: "avgbitrate", type: (.u32, 1))
    static let reserved = Synel(name: "reserved", type: (.u32, 1))
}

extension HintMediaHeaderBox: MP4Box {
    static let fourCC: FourCharCode = "hmhd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return
            parse(HintMediaHeaderBox.maxPDUSize) >-
            parse(HintMediaHeaderBox.avgPDUSize) >-
            parse(HintMediaHeaderBox.maxBitrate) >-
            parse(HintMediaHeaderBox.avgBitrate) >-
            parse(HintMediaHeaderBox.reserved)
    }
}
