//
//  SampleDescriptionBox.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct SampleDescriptionBox {
    static let entryCount = Synel(name: "entry_count", type: (.u32, 1))
}

extension SampleDescriptionBox: MP4Box {
    static let fourCC: FourCharCode = "stsd"
    var isFullBox: Bool { get { return true } }
    
    func boxParse() -> MP4Parse {
        return parse(SampleDescriptionBox.entryCount)
    }
}
