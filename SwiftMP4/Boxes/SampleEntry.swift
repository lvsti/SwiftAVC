//
//  SampleEntry.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation


struct SampleEntry {
    static let reserved = Synel(name: "reserved", type: (.u8, 6))
    static let dataReferenceIndex = Synel(name: "data_reference_index", type: (.u16, 1))
    
    static func boxParse() -> MP4Parse {
        return
            parse(SampleEntry.reserved) >-
            parse(SampleEntry.dataReferenceIndex)
    }
}
