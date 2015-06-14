//
//  AVCSampleEntry.swift
//  SwiftAVC
//
//  Created by Tamas Lustyik on 2015.06.11..
//  Copyright (c) 2015 Tamas Lustyik. All rights reserved.
//

import Foundation

struct AVCSampleEntry: MP4Box {
    static let fourCC: FourCharCode = "avc1"
    var isFullBox: Bool { get { return false } }
    
    func boxParse() -> MP4Parse {
        return VisualSampleEntry.boxParse()
    }
}

